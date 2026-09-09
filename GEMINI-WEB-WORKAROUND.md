# Gemini Web “Something went wrong” / Blank Page Workaround
# Gemini 网页“出了点问题”/ 白屏的旁路解决方法

> **Community workaround / 社区验证方法**
>
> This page documents a workaround reported repeatedly in the Gemini Apps Community and by users. It is **not an official guaranteed fix**, and the exact backend root cause has not been formally documented by Google.
>
> 本页记录的是 Gemini Apps Community 及用户多次反馈有效的**社区 workaround**。它**不是 Google 官方保证有效的修复方案**，Google 也没有正式公开说明其后台根因。

## When this is relevant / 什么时候适用

This workaround is for a **Gemini web account/session problem**, not for Antigravity’s local proxy problem.

这个方法解决的是 **Gemini 网页端账号/session 卡死**，与本仓库主体的 Antigravity 本地代理问题是两件不同的事。

Typical symptoms / 常见症状：

- You can sign in to the Google account, but `gemini.google.com` shows **“Something went wrong”** or never enters the normal chat UI.  
  Google 账号能正常登录，但进入 `gemini.google.com` 后提示 **“Something went wrong / 出了点问题”**，无法进入正常聊天界面。
- Gemini works while signed out or with another Google account, but fails only after signing in with one particular account.  
  未登录时或换另一个 Google 账号可以打开，只有某个账号登录后报错。
- The main Gemini page is blank / stuck even after ordinary browser troubleshooting.  
  Gemini 主页面白屏或卡死，普通浏览器排障没有解决。

## The “create a persona” trick / “设一个人设”的邪修方法

What people commonly describe as “setting a persona” is more precisely: **open Gemini’s Gems Creator directly, create a temporary Gem/persona, and make the Preview chat successfully answer once.**

大家口中的“去 Gemini 设个人设”，更准确地说是：**直接绕过 Gemini 主页面进入 Gems Creator，创建一个临时 Gem/人设，然后让右侧 Preview 至少成功回复一次。**

### Steps / 操作步骤

1. **Stay signed in to the affected Google account.**  
   **保持登录那个出问题的 Google 账号。**

2. Open this URL directly instead of opening the normal Gemini homepage:  
   不要先进 Gemini 首页，直接打开：

   **https://gemini.google.com/gems/create**

3. If the Gems Creator loads, create a temporary Gem/persona. The content does not matter. For example:  
   如果 Gems Creator 能正常加载，随便创建一个临时 Gem/人设，内容不重要，例如：

   - Name / 名称: `Test`
   - Instructions / 人设说明: `You are a helpful assistant.` / `你是一个乐于助人的助手。`

4. In the **Preview chat on the right-hand side**, send a simple message such as:  
   在页面**右侧 Preview/预览聊天框**里发送一句：

   `Hi`

5. **Wait until Gemini actually replies.** This is the important part.  
   **等到 Gemini 真正回复出来。**这一步最关键。

6. Return to:  
   然后重新打开：

   **https://gemini.google.com/**

   Refresh the page and try the normal chat again.  
   刷新后重新尝试正常聊天界面。

7. If the main page now works, the temporary Gem can be deleted later.  
   如果首页已经恢复，刚才临时创建的 Gem 之后删掉即可。

### If it still does not work / 如果还不行

While you are still able to open the Gems Creator page, try signing out and signing back in from that working route, then repeat the steps above. Some users report that this forces a fresh account/session initialization.  
如果 Gems Creator 能打开但 Gemini 首页还是不行，可以尝试**在这个能正常打开的 Gems 页面里退出账号，再重新登录**，然后重复上述流程。部分用户反馈这样可以进一步触发账号/session 重新初始化。

If `/gems/create` itself also fails to load, this workaround probably does not apply to your case. Try normal browser/account troubleshooting (incognito/private mode, cookies/cache, extensions, Google account/profile checks, Gemini Apps Activity) or report the account-specific problem to Google.  
如果连 `/gems/create` 都打不开，那么这个方法大概率不适用于你的故障。此时应继续检查无痕模式、Cookie/缓存、浏览器扩展、Google 账号资料、Gemini Apps Activity，或者向 Google 反馈账号级故障。

## Why can this work? / 为什么这种邪修可能有效？

Several Gemini Apps Community threads describe the main Gemini landing page becoming stuck in an account-specific backend/session state while the Gems Creator route still works. Loading the Gems Creator and successfully using its Preview appears to force Gemini to initialize or refresh account/session state through another working route. Users then report that the main Gemini page becomes usable again.

Gemini Apps Community 的多条案例显示：有时 Gemini 主页面对应的账号/session 状态卡住了，但 Gems Creator 这条独立页面路径仍然可以工作。进入 Gems Creator 并让 Preview 成功完成一次请求，**似乎能够通过另一条正常工作的路径触发账号/session 初始化或刷新**，之后主 Gemini 页面可能恢复。

This explanation is based on observed behavior and community troubleshooting. **Google has not published a formal technical root-cause explanation for this workaround**, so treat it as a practical session-reset trick rather than a guaranteed repair mechanism.

以上解释来自实际现象和社区排障经验。**Google 没有正式公开这个 workaround 的后台技术根因**，因此更适合把它理解为一个实用的 session reset/旁路重置方法，而不是百分之百保证有效的正式修复。

## Community references / 社区参考

- Gemini Apps Community — first-login “Something went wrong” solved via Gems Creator:  
  https://support.google.com/gemini/thread/435427584/
- Gemini Apps Community — persistent desktop “Something went wrong”, Gems Creator workaround:  
  https://support.google.com/gemini/thread/440304023/
- Gemini Apps Community — account-specific Gemini failure, Gems Creator bypass:  
  https://support.google.com/gemini/thread/441307364/
- Gemini Apps Community — user confirmed the Gems workaround fixed the issue:  
  https://support.google.com/gemini/thread/436277317/
- Reddit user reports of the same `/gems/create` workaround:  
  https://www.reddit.com/r/GeminiAI/comments/1pqtgcy/something_went_wrong_please_try_again_later/

## Important distinction / 注意区分

**Antigravity cannot reach the network without TUN** → use the proxy launcher in this repository.  
**Antigravity 不开 TUN 就无法联网** → 使用本仓库的 Antigravity Proxy Launcher。

**Gemini web itself shows “Something went wrong” / blank page after Google-account sign-in** → try the Gems Creator workaround on this page.  
**Gemini 网页本身在 Google 账号登录后提示“出了点问题”或白屏** → 尝试本页的 Gems Creator 旁路重置方法。
