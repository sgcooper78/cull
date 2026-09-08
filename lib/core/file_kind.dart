import 'package:path/path.dart' as p;

/// Coarse category a file falls into, used to pick a viewer.
///
/// Classification is by extension (plus a few well-known extensionless
/// names). Magic-byte sniffing is a later increment.
enum FileKind {
  image,
  video,
  audio,
  pdf,
  comic,
  archive,
  text,
  other;

  bool get isMedia => this == image || this == video || this == audio;
}

/// How an [FileKind.image] file can actually be shown.
enum ImageSupport {
  /// Flutter's built-in decoder (fast, GPU).
  native,

  /// Needs the `image` package (pure-Dart, CPU — slower, size-capped).
  package,

  /// No pure-Dart decoder on desktop (HEIC/AVIF/JXL/RAW). Metadata only.
  unsupported,
}

// --- Images -----------------------------------------------------------------

const _imageNativeExt = {
  'jpg',
  'jpeg',
  'jpe',
  'jif',
  'jfif',
  'png',
  'apng',
  'gif',
  'webp',
  'bmp',
  'dib',
  'wbmp',
};

const _imagePackageExt = {
  'tif',
  'tiff',
  'tga',
  'targa',
  'icb',
  'vda',
  'vst',
  'ico',
  'cur',
  'pnm',
  'pbm',
  'pgm',
  'ppm',
  'pcx',
  'psd',
  'exr',
  'hdr',
  'pic',
  'pvr',
  'pvrtc',
};

const _imageUnsupportedExt = {
  // Modern lossy containers with no pure-Dart decoder.
  'heic', 'heif', 'hif', 'avif', 'jxl', 'jp2', 'j2k', 'jpf', 'jpx', 'jpm',
  'jph', 'jxr', 'wdp', 'hdp',
  // Camera RAW.
  'raw', 'cr2', 'cr3', 'crw', 'nef', 'nrw', 'arw', 'srf', 'sr2', 'raf',
  'orf', 'rw2', 'rwl', 'dng', 'pef', 'ptx', 'srw', 'x3f', 'mrw', 'mdc',
  'mos', 'kdc', 'dcr', 'k25', '3fr', 'fff', 'iiq', 'erf', 'mef', 'nksc',
  // Layered / huge.
  'psb', 'xcf', 'kra', 'ora',
};

// --- Video (media_kit / ffmpeg plays essentially all of these) -------------

const _videoExt = {
  'mp4',
  'm4v',
  'm4p',
  'mkv',
  'webm',
  'mov',
  'qt',
  'avi',
  'wmv',
  'flv',
  'f4v',
  'f4p',
  'mpeg',
  'mpg',
  'mpe',
  'm1v',
  'm2v',
  'mp2v',
  'mpv',
  'ts',
  'tsv',
  'm2ts',
  'mts',
  'm2t',
  'cts',
  'm4s',
  'vob',
  'ogv',
  'ogm',
  'ogx',
  '3gp',
  '3g2',
  'asf',
  'divx',
  'dv',
  'dvr-ms',
  'wtv',
  'mxf',
  'nut',
  'y4m',
  'gxf',
  'rm',
  'rmvb',
  'amv',
  'mtv',
  'nsv',
  'roq',
  'svi',
  'viv',
  'fli',
  'flc',
  'avchd',
  'yuv',
  'h264',
  'h265',
  'hevc',
  '265',
  '264',
};

// --- Audio (media_kit plays all of these) ---------------------------------

const _audioExt = {
  'mp3',
  'flac',
  'wav',
  'wave',
  'aac',
  'm4a',
  'm4b',
  'm4r',
  'aiff',
  'aif',
  'aifc',
  'caf',
  'ogg',
  'oga',
  'opus',
  'spx',
  'wma',
  'alac',
  'ape',
  'wv',
  'tak',
  'tta',
  'mka',
  'mid',
  'midi',
  'kar',
  'mod',
  's3m',
  'xm',
  'it',
  'ac3',
  'eac3',
  'dts',
  'mp2',
  'mpc',
  'mp1',
  'amr',
  'awb',
  'au',
  'snd',
  'ra',
  'ram',
  'w64',
  '8svx',
  'voc',
  'gsm',
  'aa',
  'aax',
  'dsf',
  'dff',
  'mlp',
  'shn',
};

// --- Documents & comics --------------------------------------------------

const _pdfExt = {'pdf'};

/// Zip/tar comics get a real page reader; rar/7z/ace cannot be extracted in
/// pure Dart and fall back to a not-supported message.
const _comicExt = {'cbz', 'cbt', 'cbr', 'cb7', 'cba', 'cbw'};

const comicZipExt = {'cbz', 'cbt'};

// --- Archives (listing-only fallback) ------------------------------------

const _archiveExt = {
  'zip',
  'zipx',
  'tar',
  'gz',
  'tgz',
  'bz2',
  'tbz',
  'tbz2',
  'xz',
  'txz',
  'zst',
  'zstd',
  'tzst',
  'lz',
  'lzma',
  'lz4',
  'lzo',
  'z',
  'taz',
  '7z',
  'rar',
  'cpio',
  'ar',
  'a',
  'iso',
  'jar',
  'war',
  'ear',
  'apk',
  'xpi',
  'deb',
  'rpm',
  'pkg',
  'crx',
  'nupkg',
  'whl',
  'egg',
  'gem',
  'cab',
  'arj',
  'lha',
  'lzh',
  'ace',
  'sit',
  'sitx',
  'dmg',
};

// --- Text -------------------------------------------------------------------

const _textExt = {
  // plain / docs
  'txt', 'text', 'md', 'markdown', 'mdown', 'mkd', 'mdx', 'rst', 'adoc',
  'asciidoc', 'asc', 'org', 'textile', 'wiki', 'creole', 'pod', 'tex',
  'latex', 'ltx', 'sty', 'cls', 'bib', 'nfo', 'me', 'ms', 'man', 'roff',
  'log', 'out', 'err', 'diff', 'patch', 'rej',
  // data / config
  'json', 'json5', 'jsonc', 'jsonl', 'ndjson', 'geojson', 'topojson', 'har',
  'yaml', 'yml', 'toml', 'ini', 'cfg', 'conf', 'cnf', 'config', 'properties',
  'prop', 'env', 'dotenv', 'editorconfig', 'gitignore', 'gitattributes',
  'gitmodules', 'gitconfig', 'npmrc', 'nvmrc', 'yarnrc', 'babelrc',
  'eslintrc', 'prettierrc', 'stylelintrc', 'dockerignore', 'htaccess',
  'plist', 'reg', 'desktop', 'service', 'lock', 'sum', 'mod', 'resolved',
  'csv', 'tsv', 'psv', 'tab',
  // markup / stylesheets
  'xml', 'xsd', 'xsl', 'xslt', 'dtd', 'rng', 'svg', 'html', 'htm', 'xhtml',
  'css', 'scss', 'sass', 'less', 'styl', 'pcss', 'vue', 'svelte', 'astro',
  'hbs', 'handlebars', 'mustache', 'ejs', 'pug', 'jade', 'haml', 'slim',
  'liquid', 'njk', 'twig', 'jinja', 'jinja2', 'j2',
  // source
  // NB: `ts` is claimed by video (MPEG-TS) — TypeScript `.ts` reads as video.
  'dart', 'js', 'mjs', 'cjs', 'jsx', 'tsx', 'mts', 'coffee',
  'py', 'pyi', 'pyw', 'rb', 'rake', 'gemspec', 'php', 'phtml', 'go', 'rs',
  'c', 'h', 'cc', 'cpp', 'cxx', 'hpp', 'hh', 'hxx', 'ino', 'm', 'mm',
  'java', 'kt', 'kts', 'scala', 'sc', 'groovy', 'gradle', 'clj', 'cljs',
  'cljc', 'edn', 'ex', 'exs', 'erl', 'hrl', 'hs', 'lhs', 'elm', 'ml',
  'mli', 'fs', 'fsi', 'fsx', 'fsscript', 'ocaml', 'nim', 'nims', 'zig',
  'v', 'sv', 'svh', 'vhd', 'vhdl', 'd', 'pas', 'pp', 'lpr', 'dpr', 'vb',
  'vbs', 'bas', 'lua', 'tcl', 'r', 'rmd', 'jl', 'pl', 'pm', 't',
  'raku', 'p6', 'sql', 'ddl', 'dml', 'psql', 'proto', 'thrift', 'graphql',
  'gql', 'prisma', 'cmake', 'mk', 'mak', 'make', 'bazel', 'bzl', 'ninja',
  'gn', 'gni', 'gyp', 'gypi', 'pro', 'pri', 'cabal', 'nix', 'dhall',
  'sh', 'bash', 'zsh', 'fish', 'ksh', 'csh', 'tcsh', 'ash', 'command',
  'bat', 'cmd', 'ps1', 'psm1', 'psd1', 'awk', 'sed', 'expect',
  // subtitles (plain text)
  'srt', 'vtt', 'sbv', 'sub', 'ssa', 'ass', 'lrc',
  // misc
  'asm', 's', 'lisp', 'lsp', 'scm', 'ss', 'rkt', 'el', 'vim', 'applescript',
};

/// Extensionless / dot-only filenames that are plain text.
const _wellKnownTextNames = {
  'readme',
  'read.me',
  'license',
  'licence',
  'copying',
  'copyright',
  'unlicense',
  'authors',
  'contributors',
  'maintainers',
  'owners',
  'codeowners',
  'changelog',
  'changes',
  'history',
  'news',
  'notice',
  'todo',
  'bugs',
  'faq',
  'install',
  'hacking',
  'thanks',
  'version',
  'manifest',
  'makefile',
  'gnumakefile',
  'dockerfile',
  'containerfile',
  'vagrantfile',
  'jenkinsfile',
  'rakefile',
  'gemfile',
  'guardfile',
  'capfile',
  'berksfile',
  'brewfile',
  'podfile',
  'fastfile',
  'appfile',
  'matchfile',
  'procfile',
  'justfile',
  'earthfile',
  'caddyfile',
  'brewfile.lock',
  '.gitignore',
  '.gitattributes',
  '.gitmodules',
  '.gitconfig',
  '.mailmap',
  '.bashrc',
  '.bash_profile',
  '.bash_aliases',
  '.bash_logout',
  '.zshrc',
  '.zprofile',
  '.zshenv',
  '.profile',
  '.inputrc',
  '.vimrc',
  '.gvimrc',
  '.editorconfig',
  '.env',
  '.env.local',
  '.env.example',
  '.npmrc',
  '.nvmrc',
  '.yarnrc',
  '.prettierrc',
  '.eslintrc',
  '.stylelintrc',
  '.babelrc',
  '.dockerignore',
  '.htaccess',
  '.curlrc',
  '.wgetrc',
  '.gemrc',
  '.rspec',
  '.tool-versions',
  '.ruby-version',
  '.python-version',
  '.node-version',
};

FileKind fileKindOf(String filename) {
  final base = p.basename(filename).toLowerCase();
  if (_wellKnownTextNames.contains(base)) return FileKind.text;

  final ext = p.extension(base).replaceFirst('.', '');
  if (ext.isEmpty) return FileKind.other;

  if (_imageNativeExt.contains(ext) ||
      _imagePackageExt.contains(ext) ||
      _imageUnsupportedExt.contains(ext)) {
    return FileKind.image;
  }
  if (_videoExt.contains(ext)) return FileKind.video;
  if (_audioExt.contains(ext)) return FileKind.audio;
  if (_pdfExt.contains(ext)) return FileKind.pdf;
  if (_comicExt.contains(ext)) return FileKind.comic;
  if (_archiveExt.contains(ext)) return FileKind.archive;
  if (_textExt.contains(ext)) return FileKind.text;
  return FileKind.other;
}

/// For [FileKind.image] files: which rendering path applies.
ImageSupport imageSupportOf(String filename) {
  final ext = p.extension(filename).replaceFirst('.', '').toLowerCase();
  if (_imageNativeExt.contains(ext)) return ImageSupport.native;
  if (_imagePackageExt.contains(ext)) return ImageSupport.package;
  return ImageSupport.unsupported;
}

/// True for `.cbz` / `.cbt` — comics we can actually open (zip / tar).
bool comicIsReadable(String filename) {
  final ext = p.extension(filename).replaceFirst('.', '').toLowerCase();
  return comicZipExt.contains(ext);
}
