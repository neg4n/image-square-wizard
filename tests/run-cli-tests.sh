set -eu

ISW=$1
VIPS=$2
VIPSHEADER=$3

tmp=$(mktemp -d "${TMPDIR:-/tmp}/isw-cli-tests.XXXXXX")
trap 'rm -rf "$tmp"' EXIT INT TERM

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

assert_eq() {
    actual=$1
    expected=$2
    label=$3
    [ "$actual" = "$expected" ] || fail "$label: expected $expected, got $actual"
}

point3() {
    "$VIPS" getpoint "$1" "$2" "$3" | awk '{printf "%d,%d,%d", int($1 + 0.5), int($2 + 0.5), int($3 + 0.5)}'
}

red_at() {
    "$VIPS" getpoint "$1" "$2" "$3" | awk '{printf "%d", int($1 + 0.5)}'
}

green_at() {
    "$VIPS" getpoint "$1" "$2" "$3" | awk '{printf "%d", int($2 + 0.5)}'
}

blue_at() {
    "$VIPS" getpoint "$1" "$2" "$3" | awk '{printf "%d", int($3 + 0.5)}'
}

alpha_at() {
    "$VIPS" getpoint "$1" "$2" "$3" | awk '{printf "%d", int($4 + 0.5)}'
}

make_red_fixture() {
    "$VIPS" black "$tmp/red.v" 80 40 --bands 3
    "$VIPS" draw_rect "$tmp/red.v" "255 0 0" 0 0 80 40 --fill
    "$VIPS" copy "$tmp/red.v" "$tmp/red.png"
}

assert_gt() {
    left=$1
    right=$2
    label=$3
    [ "$left" -gt "$right" ] || fail "$label: expected $left to be greater than $right"
}

make_wide_edge_fixture() {
    "$VIPS" black "$tmp/wide.v" 90 30 --bands 3
    "$VIPS" draw_rect "$tmp/wide.v" "255 0 0" 0 0 90 15 --fill
    "$VIPS" draw_rect "$tmp/wide.v" "0 0 255" 0 15 90 15 --fill
    "$VIPS" copy "$tmp/wide.v" "$tmp/wide.png"
}

make_tall_edge_fixture() {
    "$VIPS" black "$tmp/tall.v" 30 90 --bands 3
    "$VIPS" draw_rect "$tmp/tall.v" "255 0 0" 0 0 15 90 --fill
    "$VIPS" draw_rect "$tmp/tall.v" "0 0 255" 15 0 15 90 --fill
    "$VIPS" copy "$tmp/tall.v" "$tmp/tall.png"
}

make_alpha_fixture() {
    "$VIPS" black "$tmp/alpha.v" 60 30 --bands 4
    "$VIPS" draw_rect "$tmp/alpha.v" "255 0 0 255" 0 0 30 30 --fill
    "$VIPS" draw_rect "$tmp/alpha.v" "0 255 0 0" 30 0 30 30 --fill
    "$VIPS" copy "$tmp/alpha.v" "$tmp/alpha.png"
}

make_red_fixture
"$ISW" "$tmp/red.png" "$tmp/red-solid.png"
assert_eq "$("$VIPSHEADER" -f width "$tmp/red-solid.png")" "80" "solid output width"
assert_eq "$("$VIPSHEADER" -f height "$tmp/red-solid.png")" "80" "solid output height"
assert_eq "$(point3 "$tmp/red-solid.png" 5 5)" "255,0,0" "solid top padding"

"$ISW" --blur "$tmp/red.png" "$tmp/red-blur.png"
assert_gt "$(red_at "$tmp/red-blur.png" 5 5)" "$(green_at "$tmp/red-blur.png" 5 5)" "uniform blurred padding keeps red dominant"
assert_eq "$(point3 "$tmp/red-blur.png" 5 25)" "255,0,0" "uniform blur preserves source pixels"
assert_eq "$(point3 "$tmp/red-blur.png" 5 5)" "$(point3 "$tmp/red-blur.png" 75 75)" "uniform blur fallback is solid"

make_wide_edge_fixture
"$ISW" --blur "$tmp/wide.png" "$tmp/wide-blur.png"
assert_eq "$("$VIPSHEADER" -f width "$tmp/wide-blur.png")" "90" "wide blur output width"
assert_eq "$("$VIPSHEADER" -f height "$tmp/wide-blur.png")" "90" "wide blur output height"
assert_eq "$(point3 "$tmp/wide-blur.png" 45 35)" "255,0,0" "wide blur preserves upper source pixels"
assert_eq "$(point3 "$tmp/wide-blur.png" 45 55)" "0,0,255" "wide blur preserves lower source pixels"
assert_gt "$(red_at "$tmp/wide-blur.png" 45 5)" "$(blue_at "$tmp/wide-blur.png" 45 5)" "wide top padding follows upper edge"
assert_gt "$(blue_at "$tmp/wide-blur.png" 45 85)" "$(red_at "$tmp/wide-blur.png" 45 85)" "wide bottom padding follows lower edge"

make_tall_edge_fixture
"$ISW" --blur "$tmp/tall.png" "$tmp/tall-blur.png"
assert_eq "$("$VIPSHEADER" -f width "$tmp/tall-blur.png")" "90" "tall blur output width"
assert_eq "$("$VIPSHEADER" -f height "$tmp/tall-blur.png")" "90" "tall blur output height"
assert_eq "$(point3 "$tmp/tall-blur.png" 35 45)" "255,0,0" "tall blur preserves left source pixels"
assert_eq "$(point3 "$tmp/tall-blur.png" 55 45)" "0,0,255" "tall blur preserves right source pixels"
assert_gt "$(red_at "$tmp/tall-blur.png" 5 45)" "$(blue_at "$tmp/tall-blur.png" 5 45)" "tall left padding follows left edge"
assert_gt "$(blue_at "$tmp/tall-blur.png" 85 45)" "$(red_at "$tmp/tall-blur.png" 85 45)" "tall right padding follows right edge"

make_alpha_fixture
"$ISW" --blur "$tmp/alpha.png" "$tmp/alpha-blur.png"
assert_eq "$(alpha_at "$tmp/alpha-blur.png" 5 5)" "255" "alpha blur padding is opaque"
assert_gt "$(red_at "$tmp/alpha-blur.png" 5 5)" "$(green_at "$tmp/alpha-blur.png" 5 5)" "alpha blur padding follows visible edge"
assert_eq "$(alpha_at "$tmp/alpha-blur.png" 45 20)" "0" "alpha source pixels stay transparent"

if "$ISW" --blur --rcb 1,2,3 "$tmp/red.png" "$tmp/rejected.png" 2>"$tmp/rejected.err"; then
    fail "--blur with --rcb should fail"
fi
grep -q "cannot be combined" "$tmp/rejected.err" || fail "--blur/--rcb error message missing"
