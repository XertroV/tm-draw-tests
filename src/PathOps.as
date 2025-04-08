string[]@ SplitPath(const string &in path) {
    auto file = Path::GetFileName(path);
    string[] ret = {file};

    string dirs = Path::GetDirectoryName(path.Replace("\\", "/"));
    dirs = StripStartingSlash(dirs);

    while (dirs.Length > 0) {
        // if (!dirs.EndsWith("/")) throw("Unexpected path does not end in slash: " + dirs);
        // dirs = dirs.SubStr(0, dirs.Length - 1);
        dirs = StripEndingSlash(dirs);
        ret.InsertLast(Path::GetFileName(dirs));
        dirs = Path::GetDirectoryName(dirs);
    }

    ret.Reverse();
    return ret;
}

const uint8 char_fwdSlash = "/"[0];

string StripStartingSlash(const string &in path) {
    if (path.Length == 0) return path;
    if (path[0] == char_fwdSlash) return path.SubStr(1);
    return path;
}

string StripEndingSlash(const string &in path) {
    if (path.Length == 0) return path;
    if (path[path.Length - 1] == char_fwdSlash) return path.SubStr(0, path.Length - 1);
    return path;
}
