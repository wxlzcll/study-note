### **. 安装 Git（如果未安装）**

- **Linux（Debian/Ubuntu）**：

```Bash
sudo apt update && sudo apt install git -y
```

- **macOS**： 

```Bash
brew install git  # 需先安装 Homebrew
```

- **Windows**： 下载并安装 Git for Windows

---

### **2. 配置 Git** **SSH** **密钥（如果未配置）**

#### **生成** **SSH** **密钥**（如果已有密钥可跳过）

```Bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

一路回车，默认路径保存密钥（`~/.ssh/id_ed25519`）。

#### **将****公钥****添加到** **GitHub**

1. 查看公钥：

```Bash
cat ~/.ssh/id_ed25519.pub
```

1. 复制公钥内容，登录 GitHub → Settings → SSH and GPG keys → New SSH key → 粘贴保存。

---

### **3.** **克隆****仓库

bash

```Bash
git clone git@github.com:wheelos/apollo.git
```

- **成功输出示例**：
    
- bash
    

```Bash
Cloning into 'apollo'...
remote: Enumerating objects: 100, done.
remote: Counting objects: 100% (100/100), done.
remote: Compressing objects: 100% (80/80), done.
remote: Total 100 (delta 20), reused 90 (delta 15), pack-reused 0
Receiving objects: 100% (100/100), 1.23 MiB | 2.50 MiB/s, done.
Resolving deltas: 100% (20/20), done.
```

---

### **4. 进入仓库目录**

bash

```Bash
cd apollo
```

---

### **常见问题解决**

#### **权限被拒绝（Permission denied）**

bash

```Bash
git@github.com: Permission denied (publickey).
```

- **原因**：SSH 密钥未正确配置。
    
- **解决**：
    
    - 检查密钥是否添加到 GitHub。
        
    - 测试 SSH 连接：
        
    - bash
        
    
    ```Bash
    ssh -T git@github.com
    ```
    
    - 成功会显示：`You've successfully authenticated, but GitHub does not provide shell access.`
        

#### **仓库不存在（Repository not found）**

bash

```Bash
ERROR: Repository not found.
```

- **原因**：仓库地址错误或无权访问。
    
- **解决**：
    
    - 确认仓库地址拼写正确。
        
    - 检查是否有权限访问该仓库（私有仓库需授权）。
        

---

### **备选方案（使用 HTTPS）**

如果不习惯 SSH，可以用 HTTPS 克隆：

bash

```Bash
git clone https://github.com/wheelos/apollo.git
```

- **注意**：推送代码时需要输入 GitHub 账号密码。
    

---

### **后续操作建议**

1. **查看分支**：
    
2. bash
    

```Bash
git branch -a
```

1. **切换分支**（如存在）：
    
2. bash
    

```Bash
git checkout dev
```

1. **安装依赖**（如果有）：
    
2. bash
    

```Bash
npm install  # 如果是 Node.js 项目
```

  

  

## 上述步骤的重复操作，可以选择性观看

以下是生成 ED25519 SSH 密钥的完整步骤：

### **1. 生成 SSH 密钥**

在终端执行以下命令：

bash

```Bash
ssh-keygen -t ed25519 -C "邮箱"
```

#### **操作提示解释**：

- **`Enter file in which to save the key (~/.ssh/id_ed25519)`** 直接按回车，使用默认路径 `~/.ssh/id_ed25519`。
    
- **`Enter passphrase (empty for no passphrase)`** 输入一个密码（推荐），或直接回车留空（方便但安全性低）。
    

---

### **2. 密钥生成成功输出**

bash

```Bash
Your identification has been saved in ~/.ssh/id_ed25519
Your public key has been saved in ~/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:Abc123...xyz your_email@example.com
```

---

### **3. 将公钥添加到 GitHub**

1. **查看公钥内容**：
    
2. bash
    

```Bash
cat ~/.ssh/id_ed25519.pub
```

1. 输出示例：
    
2. bash
    

```Bash
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJx7zQ1Z... 邮箱
```

1. **复制公钥**： 完整选中 `ssh-ed25519` 开头到邮箱结尾的内容。
    
2. **添加至 GitHub**：
    
    1. 登录 GitHub → **Settings** → **SSH and GPG keys** → **New SSH key**。
        
    2. **Title**：自定义名称（如 `My Laptop`）。
        
    3. **Key type**：保持默认 `Authentication Key`。
        
    4. **Key**：粘贴复制的公钥内容。
        
    5. 点击 **Add** **SSH key**。
        

---

### **4. 验证 SSH 连接**

bash

```Bash
ssh -T git@github.com
```

- **成功提示**：
    
- bash
    

```Bash
Hi username! You've successfully authenticated, but GitHub does not provide shell access.
```

---

## **常见问题解决**

### **权限错误**

bash

```Bash
Permissions 0777 for '~/.ssh/id_ed25519' are too open.
```

执行以下命令修复权限：

bash

```Bash
chmod 600 ~/.ssh/id_ed25519*
```

### **密钥冲突**

如果已有其他密钥（如 `id_rsa`），可指定新密钥：

bash

```Bash
ssh-add ~/.ssh/id_ed25519
```

---

完成上述步骤后，即可通过 SSH 克隆或操作 GitHub 仓库。

## Git clone 加速

1. 下方链接下载软件
    

https://github.com/docmirror/dev-sidecar/releases/download/v2.0.0/DevSidecar-2.0.0-linux-amd64.deb

2. 根据手动进行证书认证
    

https://github.com/docmirror/dev-sidecar/blob/master/doc/linux.md

3. 打开dev_sidecar后打开github，会看到code下面多出几条链接，随便选一条
    

  

# 团队使用git结合github开发项目的过程中一般分为两种情况。团队开发的过程一般优先情况2的方法。

## 🚦情况一：只有一个main主分支的开发

前提条件确认：如果是这个项目只有你自己开发，你是这个 GitHub 仓库的组织成员之一，并且使用ssh连接了github，那只要有 **push 权限**，就可以直接把修改推上去。（不是随便一个人clone你的项目都可以修改并提交的，能直接修改你这个仓库的设备必须要在你的github账户上配置了ssh--公钥和私钥是需要配对的）

---

## 🪜 完整流程：

### ✅ 第 1 步：查看你修改了哪些内容

```Bash
git status
```

可以看到你修改了什么文件、新增了什么文件、是否还没 add。

---

### ✅ 第 2 步：添加要提交的文件（Add）

```Bash
git add .
```

这会把所有修改添加进 Git 的暂存区。你也可以只添加某一个文件：

`git add filename.txt`

---

### ✅ 第 3 步：提交（Commit）

```Bash
git commit -m "简短清晰的提交信息，比如：修复了登录逻辑问题"
```

这个“”里面的内容就是你提交的说明，可以看到记录你这个提交了什么

---

### ✅ 第 4 步：推送（Push）到 GitHub

```Bash
git push origin main
```

> `origin` 是远程仓库名字（默认是 clone 时创建的） `main` 是你要推送的分支名称（有的仓库是 `master`，你可以用 `git branch` 查看）

---

### 🧪 小测试：如何知道自己有没有 push 成功？

你会看到像这样：

```Bash
Enumerating objects: 6, done.
Counting objects: 100% (6/6), done.
...
To github.com:xxx/your-repo.git
   abc1234..def5678  main -> main
```

表示你已成功把提交推上 GitHub 🎉

---

## ✅ 整体命令清单（复制即用）：

```Bash
cd 你的项目目录
git status
git add .
git commit -m "你的提交说明"
git push origin main
```

---

## 🔍 你可以查看一下当前所在的分支：

```Bash
git branch
```

如果你看到：

```Bash
* main
```

说明你现在就在 `main` 分支上，push 到 `origin main` 就是正确的。

---

## 🆘 常见问题快速答：

|   |   |
|---|---|
|问题|解决方法|
|push 时报权限错误|可能没有权限，或 SSH 没配置好|
|不知道当前在哪个分支|git branch|
|推送的是错的分支|git push origin 你要推的分支名|

---

## 🚦情况二：不能直接在main分支开发，需要自己创建分支开发**（PR）协作流程**

**前提条件确认：同情况一。**

## 🚨 要求创建分支提交：

有些组织要求你**不要直接 push 到 main**，而是先新建分支然后提交 Pull Request（PR）

## 🔁「**Pull Request（PR）协作流程**」

它的核心思想是：

> ❌ 不允许任何人直接改主分支（如 `main`） ✅ 每个人在 **新分支** 上开发 ✅ 提交修改后，发起 **Pull Request** → 负责人 code review → 才能合并到主分支

---

## 🪜 整个流程（需要做的）：

### **✅ 第 1 步.拉取仓库（你已经完成）**

```Bash
git clone git@github.com:org-name/repo-name.git
cd repo-name
```

---

### ✅ 第 2 步.切到主分支并更新最新代码

```Plain
git checkout main
git pull origin main
```

直接执行这个命令就好，这里再次拉取就是为了防止clone夫人时候有人修改了（一般情况下这一步有一点点多余）

### ✅ 第 3 步.**创建自己的分支**

你可以创建一个有意义的名字，比如修复登录问题：

```Bash
git checkout -b fix-login
```

这个命令会：

- 创建一个名叫 `fix-login` 的新分支
    
- 自动切换到这个分支
    

---

### ✅ 第 4 步.**开发、修改代码**

你可以在本地修改代码，然后保存。

---

### ✅ 第 5步.**提交更改到本地分支**

```Bash
git add .
git commit -m "修复登录按钮点击无效的问题"
```

---

### ✅ 第 6 步.**推送你的分支到 GitHub**

```Bash
git push origin fix-login
```

这一步会把你本地的 `fix-login` 分支推到远程仓库。

---

### ✅ 第 7 步. **去 GitHub 发起 Pull Request**

1. 打开 GitHub 页面，进入项目地址
    
2. 你第三个会看到"pull requests"，进入以后有一个"new pull request"点击一下
    
3. 填写标题和描述，然后点 "Create Pull Request"
    
4. 负责人会收到通知，**进行代码 Review**
    
5. 审核通过后，负责人会 **点击“Merge”** 把你的改动合并到主分支 🎉
    

### ✅ 第 8 步. 提issuses的方式

在github上操作，我们创建分支申请合并的时候要提一个issues，页面右边会有显示创建一个分支

![](https://ai.feishu.cn/space/api/box/stream/download/asynccode/?code=YzJhYjY0ZmYyYzgyMGQyOGY5Nzg0Y2ZmMzA5YTU5NDFfc0VlQkQwQVV5UFF3UFhMMUZ5T1I1dElnSWZCbmtsdUFfVG9rZW46WFRUSmJKZlhhb1dmdFF4MzhyU2NlNEZjbmpiXzE3NjQ5NDUyMDU6MTc2NDk0ODgwNV9WNA)![](https://ai.feishu.cn/space/api/box/stream/download/asynccode/?code=YTZhOWJmMjE2NDE0M2VkYmYxYWVkOTIwZTU0ODI0ZTZfTTB4SWttV1ZxSG5mbmdoelVxZktxRzBkR21CWWtKVFBfVG9rZW46R2RPVGI0T2Jwb3dKMEF4YURMYmNOV3J4blhkXzE3NjQ5NDUyMDU6MTc2NDk0ODgwNV9WNA)

点击以后会让你选择在哪个分支下创建新的分支，这样创建好以后你就可以

```Plain
git fetch origin
git checkout study
```

输入这个命令拉去代码，然后进入这个分支 按照步骤1，4，5，6，7的顺序开发了

这样等我们合并代码以后会自动帮我们删除分支

---

## 💡 提示：

### ✅ 查看当前分支

```Bash
git branch
```

### ✅ 查看远程分支

```Bash
git branch -r
```

---

## 🧱 整个流程总结：

```Bash
git checkout -b your-feature
# 开发中
git add .
git commit -m "说明"
git push origin your-feature
# 然后去 GitHub 页面发起 Pull Request
```

---

## 🧑🏫 为什么这么做？

|   |   |
|---|---|
|情况一|Pull Request 流程|
|直接推到 main，容易出错|所有人必须在自己的分支上提交|
|没人 review 就合并|所有改动必须审核后才合并|
|主分支容易混乱|主分支始终稳定、安全|