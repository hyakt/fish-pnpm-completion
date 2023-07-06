## ref: https://github.com/pnpm/tabtab/blob/main/lib/scripts/fish.sh
function _pnpm_completion
  set cmd (commandline -o)
  set cursor (commandline -C)
  set words (count $cmd)

  set completions (eval env DEBUG=\"" \"" COMP_CWORD=\""$words\"" COMP_LINE=\""$cmd \"" COMP_POINT=\""$cursor\"" pnpm completion -- $cmd)

  for completion in $completions
      echo -e $completion
  end
end

## ref: https://github.com/fish-shell/fish-shell/blob/master/share/completions/npm.fish
function __fish_pnpm_needs_command
    set -l cmd (commandline -opc)

    if test (count $cmd) -eq 1
        return 0
    end

    return 1
end

function __fish_pnpm_using_command
    set -l cmd (commandline -opc)

    if test (count $cmd) -gt 1
        if contains -- $cmd[2] $argv
            return 0
        end
    end

    return 1
end

# list available pnpm scripts and their parial content
function __fish_parse_pnpm_run_completions
    while read -l name
        set -l trim 20
        read -l value
        set value (string sub -l $trim -- $value)
        printf "%s\t%s\n" $name $value
    end
end

function __fish_pnpm_run
    # Complete `pnpm run` scripts
    # These are stored in package.json, which we need a tool to read.
    # python is very probably installed (we use it for other things!),
    # jq is slower but also a common tool,
    # pnpm is dog-slow and might check for updates online!
    if test -e package.json; and set -l python (__fish_anypython)
        # Warning: That weird indentation is necessary, because python.
        $python -S -c 'import json, sys; data = json.load(sys.stdin);
for k,v in data["scripts"].items(): print(k + "\t" + v[:18])' <package.json 2>/dev/null
    else if command -sq jq; and test -e package.json
        jq -r '.scripts | to_entries | map("\(.key)\t\(.value | tostring | .[0:20])") | .[]' package.json
    else if command -sq pnpm
        # Like above, only try to call pnpm if there's a command by that name to facilitate aliases that call nvm.
        command pnpm run | string match -r -v '^[^ ]|^$' | string trim | __fish_parse_pnpm_run_completions
    end
end

# all
complete -f -c pnpm -n __fish_pnpm_needs_command -a "(_pnpm_completion)" -d 'pnpm'

# run
for c in run-script run rum urn
    complete -f -c pnpm -n "__fish_pnpm_using_command $c" -a "(__fish_pnpm_run)"
    complete -f -c pnpm -n "__fish_pnpm_using_command $c" -l if-present -d "Don't error on nonexistant script"
    complete -f -c pnpm -n "__fish_pnpm_using_command $c" -l ignore-scripts -d "Don't run pre-, post- and life-cycle scripts"
    complete -x -c pnpm -n "__fish_pnpm_using_command $c" -s script-shell -d 'The shell to use for scripts'
    complete -f -c pnpm -n "__fish_pnpm_using_command $c" -l foreground-scripts -d 'Run all build scripts in the foreground'
end
