import 'package:path/path.dart' as p;

/// Root prefix for host-native fake paths: `C:\` on Windows, `/` elsewhere.
final String _root = p.separator == r'\' ? r'C:\' : '/';

/// Builds a host-native absolute path from `/`-separated segments.
///
/// The fakes and the code under test both run `package:path` in the host's
/// context, so fixtures must use the host's separator and root — a literal
/// `C:\root\a.txt` is not a well-formed path on the Linux CI runner and
/// `basename`/`dirname`/`isWithin` silently misbehave on it.
///
///     tp('root/sub/a.txt')
///       -> `C:\root\sub\a.txt` on Windows
///       -> `/root/sub/a.txt`   on POSIX
String tp([String relative = '']) =>
    p.joinAll([_root, ...relative.split('/').where((s) => s.isNotEmpty)]);
