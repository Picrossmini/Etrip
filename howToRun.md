# Etrip 运行 & 演示指南

本项目是一个 **Flutter** 应用。下面分两部分：

- **A. 第一次配环境**（队友新电脑，从零开始）
- **B. 日常运行 & 演示**（环境已就绪，每次跑项目）

---

## A. 第一次配环境（只需做一次）

### 1. 安装 Flutter SDK

1. 到 https://docs.flutter.dev/get-started/install 下载对应系统的 Flutter SDK。
2. 解压到一个无空格、无中文的路径，例如 `C:\src\flutter`。
3. 把 `flutter\bin` 加入系统环境变量 `PATH`。
4. 打开新终端验证：

    ```powershell
    flutter --version
    ```

    能输出版本号即成功。

### 2. 安装 Android Studio（模拟器在这里面）

1. 下载并安装：https://developer.android.com/studio
2. 安装向导里保持勾选：**Android SDK**、**Android SDK Platform**、**Android Virtual Device**。

### 3. 创建一个安卓模拟器（AVD）

1. 打开 Android Studio → **More Actions / 三个点 → Virtual Device Manager**（或 Device Manager）。
2. 点 **Create Device**：
    - 机型选 **Pixel** 或 **Medium Phone**；
    - 系统镜像建议选 **API 34 / 35**（点 Download 下载镜像）；
    - Finish 完成创建。

> 💡 模拟器名字每台电脑可能不同，无需和别人一致。下一步用 `flutter emulators` 查到自己的实际名字即可。

### 4. 接受授权并检查环境

```powershell
flutter doctor --android-licenses   # 一路输入 y 接受全部协议
flutter doctor                      # 检查各项是否打勾（重点看 Android toolchain）
```

如果 `flutter doctor` 里 Android 那一行有 ✗ 或警告，按它给的提示补齐即可。

### ⚠️ 常见前置坑

- **必须开启 CPU 虚拟化**：进 BIOS 打开 Intel VT-x / AMD-V，否则模拟器无法启动或极卡。
- **磁盘空间**：Android Studio + SDK + 一个镜像约需 **8–10 GB**。
- 路径里 **不要有中文或空格**。

---

## B. 日常运行 & 演示

### 1. 启动模拟器

方式一（命令行）：

```powershell
flutter emulators                          # 列出本机所有模拟器，记下名字
flutter emulators --launch <模拟器名字>     # 例如 Medium_Phone_API_36.0
```

方式二（更直观）：在 Android Studio 的 **Device Manager** 里，直接点模拟器旁边的 ▶ 启动，等屏幕亮起。

### 2. 运行项目

在**项目根目录**下执行：

```powershell
flutter pub get   # 第一次运行 / 拉取依赖后必做
flutter run       # 运行到已启动的模拟器
```

### 3. 修改后重新运行

- 热重载：在 `flutter run` 的终端按 `r`。
- 彻底重启 app：先按 `q` 退出，再 `flutter run`。

### 4. 换了图片 / 资源后还是旧内容

更新资源后需要完整重新构建，按顺序清缓存：

```powershell
flutter clean
flutter pub get
flutter run
```

---

## C. 备选方案：用真机演示（更流畅）

模拟器卡或来不及配时，可用安卓真机：

1. 手机打开 **开发者选项 → USB 调试**。
2. 数据线连电脑，手机弹窗点「允许调试」。
3. 确认设备已识别后直接运行：

    ```powershell
    flutter devices   # 能看到你的手机
    flutter run
    ```
