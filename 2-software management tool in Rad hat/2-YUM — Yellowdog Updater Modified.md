## 🟡 YUM — Yellowdog Updater Modified

### What is YUM?

YUM is the **high-level** package manager built on top of RPM. It solves RPM's biggest weakness — dependency resolution. Think of YUM as a smart assistant that uses RPM as its tool.

### 🔑 Key Advantages of YUM Over RPM

|Feature|RPM|YUM|
|---|---|---|
|Dependency resolution|❌ Manual|✅ Automatic|
|Package name required|Full filename|Short name|
|Repository support|❌ No|✅ Yes|
|Group installs|❌ No|✅ Yes|
|Transaction history|❌ No|✅ Yes (undo-able!)|
|Online package search|❌ No|✅ Yes|

### 📁 YUM Configuration

YUM's main config: `/etc/yum.conf` Repository files: `/etc/yum.repos.d/*.repo`

---

## 🏗️ Setting Up Local YUM Repository

When you don't have internet access, you set up a **local repo** from the DVD/ISO.

### Step-by-Step:

```bash
# Step 1: Create a directory to hold the repo content
mkdir /repo

# Step 2: Copy the entire DVD contents (this takes time!)
cp -rvfp /run/media/root/* /repo/
```

**Understanding the copy flags:**

|Flag|Meaning|
|---|---|
|`-r`|Recursive (copy all subdirectories)|
|`-v`|Verbose (show what's being copied)|
|`-f`|Force (overwrite without prompting)|
|`-p`|Preserve (keep original timestamps and permissions)|

```bash
# Step 3: Create the repo configuration file
cd /etc/yum.repos.d/
nano local.repo
```

**Repo file contents:**

```
[Applocal-repo]
name=AppStream software
baseurl=file:///repo/RHEL-9-7-0-BaseOS-x86_64/AppStream
gpgcheck=0
enabled=1

[BaseOSlocal-repo]
name=baseOS software
baseurl=file:///repo/RHEL-9.7-0-BaseOS-x86_64/BaseOS
gpgcheck=0
enabled=1
```

### 🔑 Understanding Repo File Fields

| Field                                        | Purpose                    | Values                                 |
| -------------------------------------------- | -------------------------- | -------------------------------------- |
| `[Applocalrepo]`<br>and `[BaseOSlocal-repo]` | Unique ID for this repo    | Any short name                         |
| `name`                                       | Human-readable name        | Any descriptive string                 |
| `baseurl`                                    | Where to find packages     | `file://` (local), `ftp://`, `http://` |
| `enabled`                                    | Is this repo active?       | `1` = yes, `0` = no                    |
| `gpgcheck`                                   | Verify package signatures? | `1` = yes (secure), `0` = no (skip)    |

> ⚠️ **Security Note:** Setting `gpgcheck=0` disables cryptographic signature verification. Only do this for trusted local repos. For internet repos, always keep `gpgcheck=1` to prevent installing tampered packages.

```bash
# Step 4: Verify the repo is working
yum repolist
```

![](https://linuxsimply.com/wp-content/uploads/2023/10/view-all-yum-repository-list.png)

---

## 📋 YUM Command Reference

### Package Listing

```bash
yum list                         # All available packages (installed + available)
yum list all                     # Same as above
yum list installed               # Only installed packages
yum list installed vsftpd        # Check if specific package is installed
yum list | more                  # View page by page
```

### Installing Packages

```bash
yum install httpd                # Install (prompts for confirmation)
yum install httpd -y             # Install without confirmation prompt
yum localinstall mypackage.rpm -y  # Install from local file (still resolves deps)
```

> 💡 **Why use `yum localinstall` instead of `rpm -ivh`?** Even for local `.rpm` files, `yum localinstall` will automatically fetch and install any missing dependencies from your configured repositories. `rpm -ivh` does NOT.

### Removing & Updating Packages

```bash
yum remove vsftpd                # Remove a package
yum update vsftpd                # Update specific package
yum update                       # Update ALL packages
```

> ⚠️ **Risk of `yum update` (no package name):** This updates EVERYTHING on the system including the kernel. On a production server, always test updates in a staging environment first, and consider using `yum update --exclude=kernel*` if you want to skip kernel updates.

### Package Information

```bash
yum info vsftpd                  # Detailed info about a package
yum provides /usr/sbin/vsftpd    # Find which package owns a file
```

### Group Operations

```bash
yum grouplist                    # List all available package groups
yum groupinstall "Development Tools" -y   # Install entire group
yum groupremove "Development Tools"       # Remove entire group
```

> 💡 **What are groups?** Groups are curated collections of related packages. For example, "Development Tools" installs gcc, make, and dozens of other dev tools at once — much easier than installing each individually.

### YUM History & Undo

```bash
yum history list                           # Show all past transactions
yum history info 5                         # Details of transaction #5
yum history package-list vsftpd           # All transactions involving vsftpd
yum history undo 5                         # UNDO transaction #5!
yum history undo last                      # Undo the most recent transaction
yum history new                            # Start a fresh history database
```

> ✅ **This is one of YUM's most powerful features!** If you install something that breaks your system, you can literally reverse the entire transaction — dependencies and all. RPM has no such capability.

YUM history is stored at: `/var/lib/yum/history/`

### Cache Management

```bash
yum clean all                    # Clear all cached metadata and packages
yum repolist                     # List all enabled repositories
```

> 💡 **When to clean cache:** After adding/modifying repo files, always run `yum clean all` so YUM re-reads the fresh metadata instead of using stale cached data.

---

## ⚠️ Risks & Best Practices with YUM

|⚠️ Risk|💡 Mitigation|
|---|---|
|`yum update` breaking production|Test in staging first; exclude kernel if risky|
|Using `-y` flag blindly|Review what will be installed/removed before confirming|
|`gpgcheck=0` in internet repos|Only disable for trusted local/internal repos|
|Stale metadata causing errors|Run `yum clean all` when repo issues occur|
|Removing a package that others depend on|YUM warns you — read the warning before confirming|
|Running out of disk space during install|Check `df -h` before large group installs|

---

### 🟡 YUM Commands

|Command|Description|
|---|---|
|`yum list`|List all available packages|
|`yum list installed`|List installed packages|
|`yum list installed vsftpd`|Check if vsftpd is installed|
|`yum install httpd`|Install package|
|`yum install httpd -y`|Install without confirmation|
|`yum localinstall pkg.rpm -y`|Install local RPM file|
|`yum remove vsftpd`|Remove package|
|`yum update vsftpd`|Update specific package|
|`yum update`|Update all packages|
|`yum info vsftpd`|Package information|
|`yum provides /path/to/file`|Find package by file|
|`yum grouplist`|List package groups|
|`yum groupinstall "Group Name" -y`|Install package group|
|`yum groupremove "Group Name"`|Remove package group|
|`yum clean all`|Clear cache|
|`yum repolist`|List enabled repos|
|`yum history list`|Show transaction history|
|`yum history undo last`|Undo last transaction|

> 📌 **Remember the Golden Rule:**
> 
> - Use **RPM** when you need fine-grained control and are working with individual package files
> - Use **YUM** for almost everything else — it's safer, smarter, and handles the hard work for you

---
