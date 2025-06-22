### PNOW 

```
nano .bashrc 
```
```
pnow() {
    echo "📁 Changing to /tmp..."
    cd /tmp || { echo "❌ Failed to cd into /tmp"; return 1; }

    # Safety check: Only delete if we're really in /tmp
    if [[ "$PWD" == "/tmp" ]]; then
        echo "🧹 Removing tmp* files in /tmp..."
        rm -rf tmp*
    else
        echo "❌ Not in /tmp, aborting delete to be safe."
        return 1
    fi

    echo "🔄 Restarting PostgreSQL..."
    sudo systemctl restart postgresql

    echo "🔄 Restarting Nginx..."
    sudo systemctl restart nginx.service

    echo "🔄 Restarting Odoo..."
    sudo systemctl restart odoo.service

    echo "✅ All services restarted successfully."
}


```



### ✅ Apply it:
```
source ~/.bashrc  
```
### ✅ Usage:
```
pnow
```

