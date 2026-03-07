function ycd
    set -l tmp (mktemp -t "yazi-cwd.XXXXX")
    yazi --cwd-file=$tmp $argv

    set -l cwd (cat -- $tmp)
    if test -n "$cwd"; and test "$cwd" != "$PWD"
        cd -- $cwd
    end

    rm -f -- $tmp
end
