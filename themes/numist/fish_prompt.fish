# name: Numist
function fish_prompt
  set -l last_status $status

  #            _                      
  #   ___ ___ | | ___  _   _ _ __ ___ 
  #  / __/ _ \| |/ _ \| | | | '__/ __|
  # | (_| (_) | | (_) | |_| | |  \__ \
  #  \___\___/|_|\___/ \__,_|_|  |___/
  #                                   
  set -l cyan (set_color -o cyan)
  set -l yellow (set_color -o yellow)
  set -l green (set_color -o green)
  set -l red (set_color -o red)
  set -l blue (set_color -o blue)
  set -l magenta (set_color magenta)
  set -l white (set_color white)
  set -l normal (set_color normal)

  #                       _       _   
  #       _ __ _ __  _ __(_)_ __ | |_ 
  #      | '__| '_ \| '__| | '_ \| __|
  #      | |  | |_) | |  | | | | | |_ 
  #  ____|_|  | .__/|_|  |_|_| |_|\__|
  # |_____|   |_|                     
  #
  # Prints first argument left-aligned, second argument right-aligned, newline
  function _rprint
    if [ (count $argv) = 1 ]
      echo -s $argv
    else
      set -l arglength (echo -n -s "$argv[1]$argv[2]" | perl -le 'while (<>) {
        s/ \e[ #%()*+\-.\/]. |
           (?:\e\[|\x9b) [ -?]* [@-~] | # CSI ... Cmd
           (?:\e\]|\x9d) .*? (?:\e\\|[\a\x9c]) | # OSC ... (ST|BEL)
           (?:\e[P^_]|[\x90\x9e\x9f]) .*? (?:\e\\|\x9c) | # (DCS|PM|APC) ... ST
           \e.|[\x80-\x9f] //xg;
        print;
      }' | awk '{printf length;}')

      set -l termwidth (tput cols)

      set -l padding
      if [ $arglength -lt $termwidth ]
        set padding (printf "%0"(math $termwidth - $arglength)"d"|tr "0" " ")
      end

      echo -s "$argv[1]$padding$argv[2]"
    end
  end

  #                   _ 
  #  _ ____      ____| |
  # | '_ \ \ /\ / / _` |
  # | |_) \ V  V / (_| |
  # | .__/ \_/\_/ \__,_|
  # |_|                 
  function _pretty_path
    pwd | sed "s:^$HOME:~:"
  end
  
  ################################################################################
  #                         _        __       
  #  ___  ___ _ __ ___     (_)_ __  / _| ___  
  # / __|/ __| '_ ` _ \    | | '_ \| |_ / _ \ 
  # \__ \ (__| | | | | |   | | | | |  _| (_) |
  # |___/\___|_| |_| |_|___|_|_| |_|_|  \___/ 
  #                   |_____|                 
  set -l scm_info
  
  #   __               _ _ 
  #  / _| ___  ___ ___(_) |
  # | |_ / _ \/ __/ __| | |
  # |  _| (_) \__ \__ \ | |
  # |_|  \___/|___/___/_|_|   
  #
  if command fossil status ^/dev/null > /dev/null
    function _fossil_branch_name
      if command fossil status | grep -q "child:"
        command fossil status | grep -e "^checkout:" | awk '{ print substr($2, 1, 10); }'
      else
        command fossil status | grep -e "^tags" | awk '{ print $2; }' | sed 's/,//' | cat
      end
    end
    
    set scm_info "$normal""on $magenta"(_fossil_branch_name)
    
    if command fossil status | grep -qe "^[A-Z]"
      set scm_info "$scm_info$yellow*"
    end
    
    set scm_info "$scm_info$normal "
  end
  
  #
  #  _____   ___ __  
  # / __\ \ / / '_ \ 
  # \__ \\ V /| | | |
  # |___/ \_/ |_| |_|
  #                 
  if svn info ^/dev/null > /dev/null
    function _svn_branch_name
      set -l revision (command svn info | grep -e "^Revision: " | awk '{print $NF}')
      set -l last_change_rev (command svn info | grep -e "^Last Changed Rev: " | awk '{print $NF}')
      if [ $revision -lt $last_change_rev ]
        echo "r"$revision
      else
        echo (basename (command svn info | grep -e "^URL: " | awk '{ print $NF; }'))
      end
    end
    
    set scm_info "$normal""on "(set_color 66FF99)(_svn_branch_name)
    
    if [ (command svn st | wc -l) -gt 0 ]
      set scm_info "$scm_info$yellow*"
    end
    
    set scm_info "$scm_info$normal "
  end
  
  #        _ _   
  #   __ _(_) |_ 
  #  / _` | | __|
  # | (_| | | |_ 
  #  \__, |_|\__|
  #  |___/        
  if git rev-parse --is-inside-work-tree ^/dev/null > /dev/null
    function _git_branch_name
      # Get the current branch name or commit
      set -l git_branch_name (command git symbolic-ref HEAD ^/dev/null | sed -e 's|^refs/heads/||')
      if [ -z $git_branch_name ]
        set git_branch_name (command git show-ref --head -s --abbrev | head -n1 2> /dev/null)
      end
      echo $git_branch_name
    end

    # Unconditional git component
    set scm_info "$normal""on $white"(_git_branch_name)

    if [ (command git status -s --ignore-submodules=dirty | wc -l) -gt 0 ]
      set scm_info "$scm_info$yellow*"
    end

    set scm_info "$scm_info$normal "
  end

  ################################################################################
  #                                  _   
  #  _ __  _ __ ___  _ __ ___  _ __ | |_ 
  # | '_ \| '__/ _ \| '_ ` _ \| '_ \| __|
  # | |_) | | | (_) | | | | | | |_) | |_ 
  # | .__/|_|  \___/|_| |_| |_| .__/ \__|
  # |_|                       |_|        

  #####################################
  # Basic information: username and pwd
  set -l basic_info $yellow(whoami)$normal" in "$blue(_pretty_path)" "

  #####################################
  # Prompt: red hash for root (danger!)
  set -l prompt
  set -l UID (id -u $USER)
  if [ "$UID" = "0" ]
    set prompt "$red# $normal"
  else
    set prompt "$normal% "
  end

  ###########
  # Job count
  set -l job_info
  set -l job_count (jobs -c | wc -l | awk '{ print $1; }')
  if [ $job_count -gt 0 ]
    if [ $job_count -eq 1 ]
      set job_info "$magenta""($job_count job)"
    else
      set job_info "$magenta""($job_count jobs)"
    end
  end

  #####################
  # Last command status
  set -l status_info ""
  if [ $last_status -ne 0 ]
    set status_info "$red""command failed with status: $last_status"
  end

  # WTB: time spend on last command (if ≥ 1s)

  ################
  # Final assembly
  if [ -n $status_info ]
    echo -s $status_info
  end
  _rprint "$basic_info$scm_info" $job_info
  echo -n -s $prompt

end
