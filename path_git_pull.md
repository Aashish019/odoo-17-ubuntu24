### For git Pull on the given path

```
find /opt/odoo17/extra-addons -type d -name ".git" -exec dirname {} \; | xargs -I{} git -C {} pull
```
### Note:
change the path to your choice

------------------------------------------------------------------------------------------------------

one-liner into a clean, safe git_pull_all.sh

```
#!/bin/bash

# Exit immediately if a command fails
set -e

echo "🔄 Pulling all git repositories under current directory..."
echo

find . -type d -name ".git" | while read -r gitdir; do
    repo_dir="$(dirname "$gitdir")"
    echo "📁 Updating: $repo_dir"
    git -C "$repo_dir" pull
    echo
done

echo "✅ All repositories updated."
```

#### 🔧 How to use it

Create the file
```
nano git_pull_all.sh
```

Paste the script, save & exit

Make it executable
```
chmod +x git_pull_all.sh
```

Run it
```
./git_pull_all.sh
```
