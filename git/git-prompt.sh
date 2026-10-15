# Git for Windows 的提示符钩子:/etc/profile.d/git-prompt.sh 发现本文件时会 source 它,
# 并跳过它自带的 PS1 —— 所以 git 补全要在这里自己补回来(见下)。
# 提示符交给便携版 starship,主题与 pwsh 侧共用 D:\data\config\starship.toml。
# 注意:本文件只在登录 shell(login shell)里被 source。

# 主题位置:bash 下 starship 同样不认 XDG_CONFIG_HOME,必须显式给
# (XDG_CONFIG_HOME=D:\data\config,路径里正反斜杠混用 Windows 程序能认)
export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"

# Git 补全:默认分支才加载,走自定义钩子就得自己来
if test -n "$BASH_VERSION" && test -z "$WINELOADERNOEXEC"; then
	_git_exec_path="$(git --exec-path 2>/dev/null)"
	_git_completion="${_git_exec_path%/libexec/git-core}"
	_git_completion="${_git_completion%/lib/git-core}/share/git/completion/git-completion.bash"
	if test -f "$_git_completion"; then
		. "$_git_completion"
	fi
	unset _git_exec_path _git_completion
fi

# ls 的目录名默认是 MSYS 的亮蓝(#3B78FF),换成主题里的蓝 #89B4FA,跟提示符一致。
# 注意:LS_COLORS 一旦显式设置,没列出的类型就不再上色 —— 所以先用 dircolors 的默认库
# 铺满全部类型,再追加一条 di= 覆盖它(同名前項后出现者生效)。
if command -v dircolors >/dev/null 2>&1; then
	eval "$(dircolors -b)"
	LS_COLORS="${LS_COLORS}di=01;38;2;137;180;250:"
	export LS_COLORS
fi

# starship:PATH 里有就用 PATH 上的,否则用 D:\program\develop\term\starship 里的便携版
if test -z "$_STARSHIP_INITIALIZED"; then
	_starship="$(command -v starship 2>/dev/null)"
	test -n "$_starship" || _starship="/d/program/develop/term/starship/starship.exe"
	if test -x "$_starship"; then
		export _STARSHIP_INITIALIZED=1
		eval "$("$_starship" init bash)"

		# starship 的 bash 集成用 PS0 + `starship time` 二进制来打时间戳(每条命令多 2 个进程,
		# 本机实测 564-836ms vs omp 270-369ms)。这里把两条都摘掉:cmd_duration 在
		# Git Bash 里不显示(pwsh 侧照旧),换回每条命令只 spawn 1 次。
		# 想要 bash 下也有 `in 2s581ms`,注释下面三行即可。
		PS0=""
		unset -f starship_preexec_ps0 starship_preexec 2>/dev/null
	fi
	unset _starship
fi

# 想换回 oh-my-posh:注释掉上面那段 starship,改成
#   _omp="/d/program/develop/term/omp"
#   eval "$("$_omp/oh-my-posh.exe" init bash --config "$_omp/catppuccin-mocha.omp.json")"
# (Git Bash 下 omp 主题里的 rprompt 不显示,也没有 transient,只有左侧提示符)
