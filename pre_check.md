### Pre Check

```
nano .git/hooks/pre-commit
```


```
#!/bin/sh
# Block commits containing "print" or "git" in .py and .xml files

# Get staged .py and .xml files
files=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(py|xml)$') || true

for file in $files; do
  if grep -nE "(^|[^a-zA-Z])print\(|(^|[^a-zA-Z])git($|[^a-zA-Z])" "$file"; then
    echo "❌ Commit blocked: Found 'print' or 'git' in $file"
    exit 1
  fi
done

exit 0
```
### Give Permmission
```
chmod +x .git/hooks/pre-commit
```
