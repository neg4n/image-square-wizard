project('image-square-wizard', 'c',
  version: '0.1.0',
  default_options: [
    'c_std=c11',
    'warning_level=3'
  ],
)

cc = meson.get_compiler('c')

warn_args = cc.get_supported_arguments([
  '-Wall', '-Wextra', '-Wpedantic', '-Werror=implicit-function-declaration',
  '-Wno-unused-parameter'
])

opt_args = cc.get_supported_arguments([
  '-O3'
])

vips_dep = dependency('vips', version: '>=8.12')

ver_def = '-DISW_VERSION="@0@"'.format(meson.project_version())
add_project_arguments(warn_args + opt_args + [ver_def], language: 'c')

srcs = files(
  'src/main.c',
  'src/isw_canvas.c',
  'src/isw_color.c'
)

isw_exe = executable('isw', srcs, install: true, install_dir: get_option('bindir'),
  dependencies: [vips_dep]
)

sh = find_program('sh')
vips_cli = find_program('vips', required: false)
vipsheader_cli = find_program('vipsheader', required: false)

if vips_cli.found() and vipsheader_cli.found()
  test('cli', sh,
    args: [files('tests/run-cli-tests.sh'), isw_exe, vips_cli.full_path(), vipsheader_cli.full_path()]
  )
endif

install_man('doc/isw.1')
