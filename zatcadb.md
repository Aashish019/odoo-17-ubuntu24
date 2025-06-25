### ZATCA 

```
nano .bashrc or .zshrc
```
```
zatcadb() {
    local db="$1"
    local pwd="123"
    local login="administrator"
    local mode="sandbox"
    local only_user_update="false"

    # Show help
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: zatcadb <db_name> [-p|--password=123] [-u|--login|--user=admin] [-m|--mode=sandbox] [-o|--only-user-update]"
        echo ""
        echo "Options:"
        echo "  -p, --password=VALUE         Set user password (default: 123)"
        echo "  -u, --login, --user=VALUE    Set login username (default: administrator)"
        echo "  -m, --mode=VALUE             Set l10n_sa_api_mode (default: sandbox)"
        echo "  -o, --only-user-update       Only update res_users table (skip company mode)"
        echo ""
        echo "Example:"
        echo "  zatcadb demo17 -p=mysecret -u=admin -m=preprod"
        echo "  zatcadb demo17 -o"
        echo ""
        echo "Created by Aashish"
        return 0
    fi

    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --password=*|-p=*) pwd="${1#*=}" ;;
            --login=*|--user=*|-u=*) login="${1#*=}" ;;
            --mode=*|-m=*) mode="${1#*=}" ;;
            --only-user-update|-o) only_user_update="true" ;;
            *) echo "Unknown option: $1"; return 1 ;;
        esac
        shift
    done

    if [ -z "$db" ]; then
        echo "❌ Error: Database name is required."
        echo "Run 'zatcadb -h' for help."
        return 1
    fi

    echo "🔧 Updating DB: $db | User: $login | Password: $pwd"
    if [[ "$only_user_update" == "true" ]]; then
        sudo -u postgres psql -d "$db" -c \
        "UPDATE res_users SET password = '$pwd' WHERE login = '$login';"
    else
        echo "🔧 Also updating l10n_sa_api_mode: $mode"
        sudo -u postgres psql -d "$db" -c \
        "UPDATE res_users SET password = '$pwd' WHERE login = '$login'; \
         UPDATE res_company SET l10n_sa_api_mode = '$mode';"
    fi
}

```



### ✅ Apply it:
```
source ~/.bashrc  # or ~/.zshrc
```
### ✅ Usage:
```
zatcadb -h
```
```
zatcadb mdt_main_17-4 -m=live
```
