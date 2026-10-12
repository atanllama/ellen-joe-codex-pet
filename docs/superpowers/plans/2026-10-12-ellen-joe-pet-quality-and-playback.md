# Ellen Joe Pixel Quality and Playback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复发布包和校验一致性，建立基于最终 WebP 的版本化播放预览，按证据优化动作，并交付可追溯的四维验收结果。

**Architecture:** Python 负责文件契约、素材锁定、打包和预览生成；安装器只验证 manifest 和批准字节，不引入 Pillow 运行依赖。浏览器播放核心与界面分开，以自包含 HTML 交付预览。所有后续工具使用同一图集和版本化配置，素材修复由逐行评估结果触发。

**Tech Stack:** Python（CI 3.12）、Pillow、pytest、PowerShell 5.1／7、POSIX sh、原生 HTML/CSS/JavaScript。JavaScript 单元测试使用 Node 内置 `node:test`；不新增 npm 包、前端构建链或应用服务。

**Spec:** [2026-10-12-ellen-joe-pet-quality-and-playback-design.md](../specs/2026-10-12-ellen-joe-pet-quality-and-playback-design.md)。执行者必须同时阅读 Spec。

**状态：** Boss 已审阅并选择 Native；2026-10-12 工程实施与本地自动检查完成，视觉／真实应用／远端 CI 缺口见 final-qa。未勾选项仍未验收。

**基线：** Spec 提交 `8f7f0c1`；产品代码基线 `5ccc1635525bebf2efb69f338f8cd5924f3d477f`。拟定版本 `v0.1.3`，未核验远端版本占用情况。

## Global Constraints

- Pet ID `ellen-joe-pixel`，显示名 `Ellen Joe Pixel`，`spriteVersionNumber: 2`，`spritesheetPath: spritesheet.webp`。
- 图集 `1536 × 2288`、`8 × 11`、单元格 `192 × 208`；占用格数 `(7, 8, 8, 4, 5, 8, 6, 6, 6, 8, 8)`。
- idle 仅第 0 行第 0–5 列；第 6 列是 neutral；第 7 列为空。注视角度 `000` 到 `337.5`，步长 `22.5`，按屏幕顺时针。
- manifest 拒绝重复顶层键、`2.0`／`2e0`／字符串／布尔版本号；接受 UTF-8 BOM、合法且不重复的未知顶层字段；键名及固定值区分大小写。
- Python 结构校验保持退出码 `0/1`；安装器保持现有 `0/2/3/4/5` 含义。锁定文件错误在目标修改前返回 `3`。
- 安装后仍只有 `pet.json` 与 `spritesheet.webp`；备份继续位于 `pet-backups`，不改变现有锁、事务和回滚约定。
- 诊断模式 `160 ms/帧`；缩放 `1×/2×`，速度 `0.5×/1×/2×`；视觉验收使用原始 `1×` 和正常速度。
- 当前 Codex 的重复、优先级和触发规则必须重新取证；禁止把历史三次播放直接写成当前默认行为。
- 美术遵循既有 identity lock；只有 `ADJUST` 行进入修复；不修改 Codex 二进制，不扩展协议或远程服务。
- QA 独立报告 `PACKAGE / INSTALLER / PREVIEW / APP`，各为 `PASS / FAIL / NOT_RUN`；未观察状态不能计为通过。
- 临时文件、虚拟环境、缓存、生成预览和测试档案统一置于 `F:\Codex Temp`；CI 使用 runner 临时目录。仓库只保存实现和精选证据。
- 本计划不包含推送、打 tag、创建 Release 或覆盖真实安装的自动执行授权；真实应用测试沿用 Spec 的独立验收边界。
- 执行方法已选定为 Native；主体顺序实施，末尾一次独立整体审查。若 Boss 选择 Subagents Mode：6.1 Sol 不超过 High、6 Astra 不超过 Medium、6 Luna 不超过 Max。

## Review Focus

1. 转义键名、未知字段嵌套重复键、大小写不同的合法键：只拒绝真正重复的顶层键，三个入口判定一致。归属 Task 1、3。
2. 空格／中文解压路径、源仓库不可见、已有输出档案：从解压包执行成功，校验失败不覆盖既有档案。归属 Task 4。
3. 缺失或半完整运行时配置：禁用不支持的播放／事件功能，不能从诊断配置偷补当前应用行为。归属 Task 6、7。
4. 页面隐藏、切换速度和暂停后的残余时长：恢复不能跳帧或意外重播。归属 Task 7、8。
5. 已打开旧预览而新生成失败，或证据对应旧图集：失败不得报告旧 HTML 为新产物，QA 哈希必须指向最终输入。归属 Task 8、10、12。

---

## 文件与责任划分

以下均相对仓库根目录。新增辅助模块属于发布工具，必须同步进入构建清单，不安装到宠物发现目录。

| 文件 | 责任 | 创建／修改 |
| --- | --- | --- |
| `scripts/manifest_contract.py` | 仅标准库的 manifest、顶层键与 lock 解析 | 新建 |
| `scripts/manifest-contract.ps1` | PowerShell 5.1／7 等价解析与值校验 | 新建 |
| `scripts/pet_contract.py`、`scripts/validate_pet.py` | 图像结构、可选批准哈希、CLI | 修改 |
| `release-assets.json`、`requirements-validator.txt` | 素材唯一哈希、用户校验依赖 | 新建 |
| `requirements-dev.txt` | 引用用户依赖并保留 pytest；工作流解析测试使用 PyYAML | 修改 |
| `scripts/install.ps1`、`scripts/install.sh` | 调用共享契约、读取素材锁定 | 修改 |
| `scripts/build_release.py` | 先验源校验、完整发布清单、可复现打包 | 修改 |
| `scripts/build_contact_sheet.py` | 从最终 WebP 生成随包标准动作预览图 | 新建 |
| `scripts/playback_profile.py` | 播放配置结构及证据等级校验 | 新建 |
| `scripts/preview/playback.mjs` | 无 DOM 的播放状态机 | 新建 |
| `scripts/preview/template.html`、`style.css`、`ui.js` | 预览显示、控件和浏览器事件适配 | 新建 |
| `scripts/build_preview.py` | 生成自包含 HTML，不写正式素材 | 新建 |
| `tests/fixtures/manifest-cases.json` | 以原始 JSON 文本保存共享输入语料 | 新建 |
| `tests/test_manifest_contract.py`、`test_release_assets.py`、`test_installer_contract.py` | 契约及跨 shell 判定 | 新建 |
| `tests/test_release_archive.py`、`test_contact_sheet.py` | 解压包用户流程、预览图来源 | 新建 |
| `tests/test_playback_profile.py`、`test_preview.py`、`playback.test.mjs` | 配置、HTML 生成和播放核心 | 新建 |
| 现有 `tests/test_pet_contract.py`、`test_build_release.py`、`test_ci_workflows.py`、安装测试 | 保留回归并适配新增支持文件 | 修改 |
| `.github/workflows/checks.yml` | 同一提交的可复用检查矩阵 | 新建 |
| `.github/workflows/validate.yml`、`release.yml` | 调用检查矩阵并约束发布依赖 | 修改 |
| `qa/playback/v0.1.3/` | 本轮运行时证据、配置、评估及四维 QA | 新建 |
| `README.md`、`README.zh-CN.md`、`docs/releases/v0.1.3.md` | 可执行的用户说明和版本边界 | 修改／新建 |

## 执行准备与依赖顺序

这是一份联合计划：A 阶段可独立验收，B 阶段复用其图集契约和哈希，C／D 再验证同一交付物；无需同时推进两套独立实现。

顺序：`准备 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10（条件）→ 11 → 12`。

- [x] 阅读当前仓库指令，记录 `git status --short`、分支与 HEAD；如状态变化，保留用户改动并调整基线。
- [x] 检查已有附属 worktree；实施时按 using-git-worktrees 技能复用合适 checkout，必要时新建 `codex/` 分支。计划编写不创建 worktree。
- [x] 在 `F:\Codex Temp` 创建唯一运行目录，以 `$petRunRoot` 引用；进程级 `TEMP/TMP/PYTHONDONTWRITEBYTECODE` 指向该目录或禁用字节码；不改动 `HOME/CODEX_HOME`。
- [x] 创建本轮 Python 环境并安装仓库开发依赖；记录 Python、Pillow、pytest、PowerShell、Node 版本。Node 可用应用提供的运行时，绝不因此增加预览用户依赖。
- [x] 运行基线 `python -B -m pytest -q -p no:cacheprovider --basetemp "$petRunRoot\baseline-tests"` 和现有包校验；预期原有 13 项及当前包通过。若实际基线不同，先记录解释，不沿用历史 PASS。

下文命令在仓库根目录执行；Python 指本轮环境。pytest 使用上述临时根约定，各轮 basetemp 使用独立子目录。所有 Git 提交只 stage 本任务明确列出的文件，禁止 `git add .`。

## Task 1：统一 Python manifest 与图集结构校验

**Files:** 新建 `scripts/manifest_contract.py`、`tests/fixtures/manifest-cases.json`、`tests/test_manifest_contract.py`；修改 `scripts/pet_contract.py`、`tests/test_pet_contract.py`。

**Interfaces:**
- `parse_manifest(text: str) -> dict[str, object]`：接受开头 BOM，返回合法对象，失败抛 `ValueError`。
- 保留 `validate_package(pet_dir: Path) -> list[str]`；错误字符串含字段或行列，不泄漏整份文件。
- 语料每项 `{name: str, text: str, valid: bool}`；`text` 保留原始数值拼写及重复键，禁止先序列化为字典丢失证据。

- [x] **写失败测试。** 增加 `test_manifest_cases`，逐项断言 `parse_manifest` 返回对象或抛 `ValueError`；至少包括 `2.0/2e0/"2"/true`、重复五个约定键、重复未知键、转义后相同键、错误大小写、空描述、BOM、不同大小写未知键、嵌套重复未知键、畸形 JSON、尾随垃圾和非标准 `NaN/Infinity`。嵌套重复未知键沿用现有 POSIX 接受行为，顶层重复拒绝。
- [x] **写图集失败测试。** `test_disguised_png_rejected`、`test_animated_webp_rejected`、`test_missing_alpha_rejected`，断言对应错误；动画 fixture 必须有两帧不同像素，保证编码器未合并。保留尺寸、使用格与空格测试。
- [x] **运行 RED。** `python -B -m pytest tests/test_manifest_contract.py tests/test_pet_contract.py -q -p no:cacheprovider`；预期新增 API 缺失或错误输入被接受，不能把测试配置错误当业务 RED。
- [x] **实现解析与格式检查。** Python 使用保留 object pairs 的标准库解析区分顶层重复和嵌套内容，拒绝非 JSON 常量；整数判断用精确类型。Pillow 在 `.convert('RGBA')` 前检查格式、动画标志及 alpha，随后复用格子检测。
- [x] **运行 GREEN。** 同一命令全部通过；当前真实 WebP 仍通过 CLI。
- [x] **提交。** `fix: enforce manifest types and static WebP contract`。

## Task 2：集中批准哈希与校验依赖

**Files:** 新建 `release-assets.json`、`requirements-validator.txt`、`tests/test_release_assets.py`；修改 `scripts/manifest_contract.py`、`scripts/pet_contract.py`、`scripts/validate_pet.py`、`requirements-dev.txt`。

**Interfaces:**
- `parse_asset_lock(text: str) -> dict[str, object]`：仅接受 Spec 的三个字段，严格整数 schemaVersion `1`、固定 petId、小写 64 位哈希；失败抛 `ValueError`。
- `validate_package(pet_dir: Path, *, asset_lock: Path | None = None) -> list[str]`：兼容旧调用；提供 lock 时追加批准字节检查。
- CLI：`python scripts/validate_pet.py <pet_dir> [--asset-lock <path>]`；成功 `0`，无效输入 `1`。

- [x] **写失败测试。** `test_structure_valid_but_unapproved_bytes` 使用一个结构合法的修改副本，断言无 lock 时 `[]`，有 lock 时含 hash mismatch；`test_invalid_lock` 覆盖缺文件、错 petId、`1.0`、重复键、大写／错误长度哈希。CLI 对坏 lock 返回 `1` 且不打印 traceback。
- [x] **运行 RED。** `python -B -m pytest tests/test_release_assets.py -q -p no:cacheprovider`。
- [x] **实现 API 与依赖清单。** lock 初始哈希取 Spec 基线并与真实文件核对，禁止自动更新批准值。`requirements-validator.txt` 使用 `Pillow>=10`；开发清单引用它并保留 `pytest>=8`。
- [x] **运行 GREEN。** 相关测试通过；`python -B scripts/validate_pet.py pet/ellen-joe-pixel --asset-lock release-assets.json` 返回 `0`；lock 不复制进 pet 目录。
- [x] **提交。** `feat: centralize approved pet asset hash`。

## Task 3：安装器使用同一语料与锁定文件

**Files:** 新建 `scripts/manifest-contract.ps1`、`tests/test_installer_contract.py`；修改 `scripts/install.ps1`、`scripts/install.sh`、`scripts/manifest_contract.py`、`tests/install-windows.ps1`、`tests/install-posix.sh`。

**Interfaces:**
- Python 辅助 CLI：`python scripts/manifest_contract.py --manifest <path> --asset-lock <path>`；成功输出批准哈希并返回 `0`，错误返回 `1`、stderr 给出原因。仅标准库依赖。
- PowerShell `Read-ApprovedPetHash([string]$ManifestPath, [string]$AssetLockPath) -> [string]`；成功返回同一哈希，错误 throw，由安装入口映射为退出码 `3`。
- `tests/install-windows.ps1 -ShellPath <path>`：新增可选参数，默认当前 PowerShell 可执行文件；子进程不再固定调用 `pwsh`。

- [x] **写失败测试。** 共享语料逐项喂给 Python、`pwsh`、`powershell.exe` 和可用的 POSIX installer；有效输入安装返回 `0`，无效输入返回 `3`，目标及 sentinel 字节不变。每个语料使用独立 fixture home；缺少 shell 只在不适用平台 skip，CI 对本平台应有 shell 缺失视为失败。
- [x] **补 lock 回归。** 缺失、畸形、错误 hash 在首次和 `-Force/--force` 路径均拒绝且原安装不变；fixture 必须复制两个新增辅助模块与 lock。历史故障注入断言继续命中真实最终移动／回滚分支。
- [x] **运行 RED。** `python -B -m pytest tests/test_installer_contract.py -q -p no:cacheprovider`，预期当前宽松判定或缺辅助入口失败。
- [x] **实现等价入口。** POSIX 用 Task 2 的标准库 CLI 替换内嵌重复解析；PowerShell 5.1／7 用保留原始顶层值 token 的 JSON 扫描读取键和值，不能先经大小写不敏感对象折叠。必须正确处理转义、嵌套、字符串中的标点和完整 JSON 语法；仅对已选出的标量解码，不能用正则枚举整份 JSON 键。共享 fixture 是行为规范。
- [x] **实现 lock 接入。** 在创建 home／锁／暂存前读取 lock，保留哈希工具与事务代码；Windows 继续不依赖 Python。只复制两个 pet 文件到目标。
- [x] **运行 GREEN 与安装回归。** Windows 分别执行 `pwsh -NoProfile -File tests/install-windows.ps1 -ShellPath pwsh` 和 `powershell.exe -NoProfile -File tests/install-windows.ps1 -ShellPath powershell.exe`；POSIX 执行 `sh tests/install-posix.sh`。预期原有安装、拒绝覆盖、备份、回滚、卸载和 sentinel 断言全部通过。
- [x] **提交。** `fix: align installer manifest and asset validation`。

## Task 4：发布包自包含与真实解压流程

**Files:** 新建 `scripts/build_contact_sheet.py`、`tests/test_contact_sheet.py`、`tests/test_release_archive.py`、`docs/releases/v0.1.3.md`；修改 `scripts/build_release.py`、`tests/test_build_release.py`、`README.md`、`README.zh-CN.md`、`qa/contact-sheet-standard.png`。

**Interfaces:**
- 保留 `build_release(repo_root: Path, version: str, output_dir: Path) -> tuple[Path, Path, Path]`；源检查失败不得创建或覆盖正式档案。
- `build_contact_sheet(pet_dir: Path, output: Path) -> Path`；CLI `--pet-dir <dir> --output <png>`，从最终 WebP 制图，neutral 标注为保留槽。
- `release_inputs(version: str) -> tuple[str, ...]`：现有基础清单＋Spec 新增文件＋Task 1/3 辅助模块＋相应版本说明；不打包开发测试和完整 QA。

- [x] **写失败测试。** `test_archive_can_validate_without_checkout` 对 ZIP／tar.gz 独立解压，在带空格和中文的临时目录 subprocess 运行包内校验器，清除 `PYTHONPATH` 并将 cwd 设为解压根；断言退出 `0`。断言包内包含辅助模块与 `requirements-validator.txt`，不含 pytest、开发测试或预览开发工具。
- [x] **写用户流程和构建回归。** `test_archive_install_lifecycle` 使用解压后的脚本检查首次安装 `0`、重复 `2`、强制备份 `0`、卸载 `0` 和 sentinel 不变；`test_invalid_source_preserves_existing_archives` 断言既有输出字节不变；`test_readme_user_links_resolve` 检查用户章节本地链接；`test_contact_sheet_uses_final_cells` 比较非文字绘图区与最终图集对应像素。
- [x] **运行 RED。** `python -B -m pytest tests/test_release_archive.py tests/test_contact_sheet.py tests/test_build_release.py -q -p no:cacheprovider`。
- [x] **替换失效 fixture。** 现有 `fake_repo()` 使用假 WebP 和任意文本，改用真实的最小有效 WebP、manifest、匹配 lock 与版本说明。换行测试只改变文本换行，WebP／PNG 原始字节不变；不 mock 掉构建前校验。
- [x] **实现构建与说明。** 构建先调用 Task 2 的完整校验再写档案；保留可复现时间戳和权限。双语 README 使用 `requirements-validator.txt` 和可选 lock 命令，贡献段落标明完整仓库；去除需手改的重复哈希常量，指向 lock。版本说明标为尚未发布，不把历史支持证据写成当前已测。
- [x] **运行 GREEN。** 同一测试集通过，分别检查 ZIP／tar.gz 流程。使用真实图集生成联系图，人工看一次身份、标签和无误裁切；生成图只作为素材派生图，不做 AI 重绘。
- [x] **提交。** `fix: ship self-contained validated release archives`。

## Task 5：核查当前运行时并记录能力边界

**Files:** 新建 `qa/playback/v0.1.3/runtime-evidence.md`；其他运行时原始摘录放临时目录，不提交应用 bundle。

**Interfaces:** 产出给 Task 6 的证据：应用版本、时间、来源定位／文件 SHA-256、状态帧序列、时长、重复、结束行为、优先级、中断及注视触发；每项为 `STATIC_VERIFIED`、`APP_OBSERVED` 或 `UNKNOWN`。

- [x] **记录版本和素材身份。** 只读确定当前 Codex 安装及实际宠物文件位置，哈希对比仓库；不假设当前 `CODEX_HOME` 与旧记录一致，不主动升级应用。
- [x] **核查播放实现。** 优先使用可访问的本地代码／资源，记录最小必要定位和证据摘要；找不到的行为标记 `UNKNOWN`。不要把旧构建的三次播放或优先级粘贴成当前结论。
- [x] **整理可模拟与未知项。** 逐项列出哪些动作序列完整、哪些事件可模拟。所需核心规则全未知时，交付诊断模式仍可继续 Task 6–8，但明确 Codex 模式不可用；不伪造证据解锁功能。
- [x] **验证证据完整性。** 当前日期、应用版本和来源指纹齐全；每个已确认值有来源；静态结果没有标成实际观察。此任务为调查，不写虚假的先失败测试。
- [x] **提交。** `docs: record versioned Codex playback evidence`。

## Task 6：播放配置与固定图集映射

**Files:** 新建 `scripts/playback_profile.py`、`tests/test_playback_profile.py`、`qa/playback/v0.1.3/diagnostic-profile.json`、`qa/playback/v0.1.3/codex-profile.json`。

**Interfaces:** `load_profile(path: Path) -> dict[str, object]` 验证并返回配置，错误抛 `ValueError`。不读机器当前应用状态，不修改配置。结构如下：

```text
schemaVersion: 1
kind: "diagnostic" | "codex"
appVersion: string | null
capturedAt: ISO date
evidence: [{id, level: STATIC_VERIFIED|APP_OBSERVED, source, fingerprint}]
actions: {state: {frames: [{row, col, durationMs}], repeatCount: positive-int|null,
                  after: "hold"|"idle"|"loop"|null, evidenceIds: [id]}}
events: {priority: [state]|null, transitions: [rule]|null, lookTrigger: string|null}
```

`frames`／单帧 duration 未知用 `null`；完整动作定义为合法帧列表、有限正时长、正整数 repeatCount 和已知 after。Codex 核心不完整时整个 Codex 模式不可用，界面不悄悄切换诊断模式。已知播放但 events 不完整只禁用事件模拟。

- [x] **写失败测试。** `test_diagnostic_maps_26_choices` 断言九状态＋neutral＋16方向共 `26` 项，idle 六帧列 `0..5`，neutral `[0,6]`，方向依序落在行 `9/10`；`test_diagnostic_timing` 断言每帧 `160`。`test_incomplete_codex_disables_mode`、`test_unknown_events_disable_only_simulation` 断言对应能力标志。
- [x] **补非法配置测试。** 越界／空白格、0／负数／非有限 duration、布尔 repeatCount、重复／缺失标准状态、引用不存在证据、Codex 缺应用版本必须拒绝；诊断配置不能冒用运行时证据等级。
- [x] **运行 RED。** `python -B -m pytest tests/test_playback_profile.py -q -p no:cacheprovider`。
- [x] **实现映射与配置验证。** 增加 `profile_capabilities(profile: dict[str, object]) -> dict[str, bool]` 返回 `codexPlayback` 与 `eventSimulation`。Codex 配置只填 Task 5 确认的值；未知保留 null，诊断配置使用单轮 repeatCount `1`、after `hold`。
- [x] **确定事件规则格式。** 已确认规则写为 `{from, event, to, restart: bool, evidenceIds}`；事件名包含 `work/waiting/failed/review/idle`，`work` 映射到动作 `running`。优先级用于当前活跃条件集合的选择，transition 决定切换／重播；未被此结构表达的运行时行为标记不支持并禁用事件模拟，不自行近似。
- [x] **运行 GREEN 并提交。** 测试通过后提交 `feat: define evidence-backed playback profiles`。

## Task 7：无界面的确定性播放核心

**Files:** 新建 `scripts/preview/playback.mjs`、`tests/playback.test.mjs`。

**Interfaces:**
- `createPlayback(profile, action, mode = 'once') -> PlaybackState`。
- `reducePlayback(state, command) -> PlaybackState`，纯函数；command 类型为 `tick(deltaMs)`、`play`、`pause`、`replay`、`step(direction)`、`select(action)`、`mode(value)`、`speed(value)`、`visibility(hidden)`、`conditions(activeStates)`。
- state 至少包含 `action/mode/frameIndex/elapsedMs/phase/playing/speed/hidden/wasPlaying`；`currentFrame(state) -> {row,col,durationMs}`。tick 不读取真实时钟，DOM 层负责提供 delta。

- [x] **写失败测试。** Node `assert` 明确验证以下值：

```javascript
assert.equal(currentFrame(tick(idleOnce, 160)).col, 1);
assert.equal(currentFrame(tick(idleOnce, 959)).col, 5);
assert.equal(tick(idleOnce, 960).playing, false);
assert.equal(currentFrame(tick(idleLoop, 960)).col, 0);
```

测试 helper `tick(s, ms)` 调用 `reducePlayback(s, {type:'tick', deltaMs:ms})`；`idleOnce/idleLoop` 为 playing 状态的诊断配置。其他 command 同样用 `{type, ...}` 对象。

- [x] **覆盖控制和合成运行时。** `pause_preserves_remainder`：80 ms 后暂停、tick 5000、恢复再80 ms恰好进一帧；`visibility_no_catchup` 同样保持余量并只在先前播放时恢复；`select_resets` 切换从0开始；step 暂停且边界夹住；速度2×用80 ms进一帧。仅测试中构造 repeatCount=3 的合成配置，验证结束策略及 events；明确它不是当前 Codex 事实。
- [x] **运行 RED。** `node --test tests/playback.test.mjs`；预期模块未定义失败。
- [x] **实现状态机。** once 忽略 profile 的重复／结束策略并停末帧，loop 连续重复选定序列，codex 才使用配置；mode/select/replay 清零帧进度，speed 保留已累计的动画时间。显式阶段区分所选动作、后续 idle 与 stopped；未知规则禁用，禁止回退猜测。
- [x] **运行 GREEN。** 同一 Node 测试全部通过；追加针对 Task 5 已确认事件的证据 fixture 验证 work→waiting/failed/review 和完成去向，未知事件保留不支持测试。
- [x] **提交。** `feat: add deterministic pet playback engine`。

## Task 8：生成自包含预览并验证浏览器交互

**Files:** 新建 `scripts/build_preview.py`、`scripts/preview/template.html`、`scripts/preview/style.css`、`scripts/preview/ui.js`、`tests/test_preview.py`；新建 `qa/playback/v0.1.3/preview-checklist.md`。

**Interfaces:** `build_preview(pet_dir: Path, profile_path: Path, output: Path) -> Path`；CLI `--pet-dir`、`--profile`、可选 `--output`。未指定输出时写入唯一临时运行目录的 `preview.html` 并打印绝对路径；失败返回 `1`。

- [x] **写失败测试。** `test_preview_embeds_exact_webp` 从 HTML 的 data URL 解码后与输入字节完全相同；`test_preview_is_self_contained` 断言 CSS、engine、UI 内嵌且无远程 URL／模块 import；`test_bad_input_preserves_previous_output` 先保存旧 HTML，输入坏配置后返回失败、旧字节不变且不打印成功链接；`test_untrusted_profile_text_stays_data` 覆盖 `</script>` 字符串，仅作为文本展示。
- [x] **运行 RED。** `python -B -m pytest tests/test_preview.py -q -p no:cacheprovider`。
- [x] **实现生成器。** 调用 Task 1 的结构校验与 Task 6 配置校验，不强制候选匹配批准 lock；嵌入精确 WebP、SHA-256 和配置。内联同一模块内拼接 engine/UI，避免 file URL import 限制；校验与生成完成后原子替换输出，只在成功后打印路径。
- [x] **实现最小 UI。** 状态选择、once/loop/codex、播放／暂停／重播／步进、1×/2×、0.5×/1×/2×、三种背景、行列／阶段显示及证据标签。手动动作与活跃条件模拟分区；不支持的模式显示禁用原因。隐藏页面时由 DOM 适配器重置墙钟锚点，防止恢复时大 delta 破坏 Task 7 的约定。
- [x] **运行 GREEN。** Python／Node 相关测试通过；生成诊断 HTML 到临时目录。
- [ ] **浏览器验收。** 用可用浏览器工具打开生成文件，按 checklist 实测每类控件、26项选择、半帧暂停恢复、隐藏恢复、无效模式禁用，以及深浅背景和2×清晰度；在离线／无网络依赖条件下可用。记录浏览器版本、输入哈希和实际观察；不能用 HTML 文本检查代替交互验收。
- [x] **提交。** `feat: provide self-contained pet playback preview`；不提交生成 HTML 或浏览器缓存。

## Task 9：现有素材逐行评估

**Files:** 新建 `qa/playback/v0.1.3/action-assessment.md`、`qa/playback/v0.1.3/look-regression.md`，精选截图保存在同目录。

**Interfaces:** 每行字段为 `state / assetSha256 / profile / evidenceLevel / nativeSizeObservation / loopSeam / idleTransition / identity / semantic / verdict / evidence / reviewer`；verdict 仅 `RETAIN/ADJUST/UNVERIFIED`。

- [x] **建立评估输入。** 对当前最终素材生成诊断与可用的 Codex 模式预览；配置不完整时记录限制，不补写“真实播放通过”。
- [ ] **逐行观察九个状态。** 按 waving、jumping、failed、running、review 优先，再检查 idle、左右移动、waiting。1× 正常速度看完整序列、首尾、回 idle，必要时逐帧定位具体行列。
- [x] **复查16方向。** 检查顺时针、`157.5→180`、`337.5→000`、尾部连接和角色一致性；历史七项轻微警告逐项标明保留或变化，不默认推翻已接受结论。
- [x] **给出可执行结论。** `ADJUST` 必须有具体缺陷与目标效果；缺证据写 `UNVERIFIED`。诊断中的问题与已确认应用播放问题分列；没有问题时不制造修复需求。
- [x] **检查完整性并提交。** 九行齐全、证据路径可访问、素材及配置哈希正确；提交 `docs: assess current pet animations and look continuity`。

## Task 10：仅修复被确认的问题行（条件任务）

**Files:** 仅有 `ADJUST` 时修改 `pet/ellen-joe-pixel/spritesheet.webp`、`release-assets.json`、`qa/contact-sheet-standard.png`；新建 `qa/playback/v0.1.3/repair-record.md`，更新 Task 9 评估表。

**Interfaces:** 消费明确问题行与 Task 8 预览；产出候选／基线哈希、修改行列表、未改行像素一致性报告和最终评估。

- [x] **判定是否进入。** 无 `ADJUST` 则记录 `SKIPPED — no confirmed repair required`，核对基线哈希未变，直接进入 Task 11；`UNVERIFIED` 不触发生成。
- [ ] **保存基线并形成修复目标。** 基线图集和每行解码像素保存在临时目录；每个修复目标对应 Task 9 证据。执行美术生成前读取适用 imagegen 技能，以当前批准素材作为参考。
- [ ] **生成并评估候选。** 通过图像生成／编辑工具生成完整问题行；生成源与失败候选留临时目录。确定性工具仅做协议所需提取、对齐、组装和检验，不代替美术重绘。
- [ ] **验证候选。** 结构校验、身份／道具／透明度、1×播放、循环与切换均通过；每条未改行 `candidateRGBA == baselineRGBA`。最终编码采用可保持未改行解码像素的方式，再解码复核，不只比较编码前中间图。
- [ ] **提升最终素材。** 仅候选通过后替换 WebP、显式更新 lock、重建联系图／HTML、更新评估及修复记录；重新执行批准哈希校验和受影响测试。发生新回归就保留原正式素材并继续修复。
- [ ] **提交。** `fix: refine confirmed pet animation defects`；未解决问题保留 `ADJUST`，不得进入“全部完成”结论。

## Task 11：同一提交的跨平台检查与发布依赖

**Files:** 新建 `.github/workflows/checks.yml`；修改 `.github/workflows/validate.yml`、`.github/workflows/release.yml`、`tests/test_ci_workflows.py`、`requirements-dev.txt`。

**Interfaces:** `checks.yml` 使用 `workflow_call`，在调用提交运行三平台矩阵；validate 和 release 都通过本地 reusable workflow 引用。release 发布 job 的 `needs: checks`，权限只在发布 job 赋予 `contents: write`。

- [x] **写失败测试。** 使用 PyYAML 读取工作流结构（注意 YAML 1.1 对 `on` 的解析，使用保留字符串键的 loader），断言三 OS、Python3.12、Node 内置测试、包结构＋lock、两种 Windows shell、POSIX 及独立解压测试均存在；release 必须依赖同一 workflow 的 checks，不能查询其他提交的历史绿灯。把现有精确缩进／`setup-python@v7` 字符串测试改为结构约束，不锁死无关动作版本。
- [x] **运行 RED。** `python -B -m pytest tests/test_ci_workflows.py -q -p no:cacheprovider`。
- [x] **实现 reusable checks。** 每平台安装开发依赖、跑 Python／Node 测试与平台安装回归；缓存键同时包含两个 requirements 文件。缺少必需 shell 或命令不能静默 skip；本地缺其他 OS 记录 `NOT_RUN`，留给真实矩阵执行。
- [ ] **实现发布依赖。** 发布 job 在 checks 全部成功后重新检验并构建同一 tag 的档案；从本次版本说明读取发布文本。保留 `--verify-tag`，不在实施时创建 tag 或调用发布步骤。
- [x] **运行 GREEN 并提交。** 本地结构测试通过后提交 `ci: gate release on same-commit cross-platform checks`。授权运行远端 CI 后记录实际结果；未运行不能把结构测试当 CI 成功。

## Task 12：最终包、真实应用验证和交付记录

**Files:** 新建 `qa/playback/v0.1.3/final-qa.md`、`qa/playback/v0.1.3/app-observation.md`；更新 `docs/releases/v0.1.3.md` 与双语 README 中实际可证实的信息。

**Interfaces:** `final-qa.md` 逐项映射 AC-01–12，记录四维状态、最终提交、图集哈希、预览配置、档案哈希、工具／平台版本、命令、退出码及证据；无法执行项带原因和所需人工操作。

- [x] **运行最终自动检查。** `python -B -m pytest -q -p no:cacheprovider`、`node --test tests/playback.test.mjs`、带 lock 的 CLI、可用平台安装回归。有效变更后的最终字节运行一次；仅有新失败或新修改才重复扩测。
- [x] **构建与解压验收。** `python -B scripts/build_release.py --repo-root . --version v0.1.3 --output-dir "$petRunRoot\final-dist"`；分别校验 ZIP／tar.gz、SHA256SUMS，以及独立解压后的安装和校验。发布版号若已被使用，先更新文档和构建参数，禁止覆盖远端版本。
- [x] **核对最终视觉证据。** 从最终 WebP 重建预览；素材变更后重新评估受影响动作和关键衔接，记录路径／配置／哈希；旧图集截图不能作为新图集验收。
- [x] **准备应用内测试。** 记录当前应用版本、发现目录、已安装哈希和目标版本；如需覆盖真实安装，先给 Boss 可审阅的具体候选和已完成验证结果，取得已有授权范围内的明确安装许可后执行。无权限／无操作工具则保留 `APP: NOT_RUN`，交付精确人工检查步骤。
- [ ] **实际观察。** 确认选择器唯一条目、idle、work、review，观察可安全触发的 waving/jumping/failed 和注视行为。录屏或有步骤和验收者的记录证明循环／切换；不可触发项逐项 `NOT_RUN`，不用虚构任务制造画面。发现素材问题回到 Task 9/10，版本规则改变回到 Task 5/6。
- [x] **填写四维结果和说明。** 应用必检状态未观察则 APP 不能 PASS；跨平台未实跑则 INSTALLER 不能全平台 PASS。删除未得到证据的完成声明；不复用历史豁免。
- [x] **文档检查并提交。** `git diff --check`、链接及 AC 覆盖检查通过后，提交 `docs: record pet quality and playback acceptance`；记录文档提交与已验证产品提交的对应关系。如更改非文档代码／素材，重跑受影响门禁。
- [x] **交付。** 向 Boss 提供最终 Spec/Plan、已勾选任务、档案、哈希、预览入口、四维 QA 和所有未完成项；本计划到此结束，不推送、不发版。需要发布时另行处理真实 CI、远端版本和公开发布决定。

## 验收映射与阶段出口

| Spec 验收 | 负责任务 | 完成证据 |
| --- | --- | --- |
| AC-01 发布包自包含 | 4、12 | 两种档案独立解压的命令与结果 |
| AC-02 已知校验遗漏 | 1、2 | 异常样本拒绝、原包通过 |
| AC-03 跨入口一致性 | 1、3、11 | 同一原始 JSON 语料的 Python／PS5.1／PS7／POSIX 结果 |
| AC-04 图集格式布局 | 1、6、7 | 格式／占用测试、neutral 与 idle 分离 |
| AC-05 哈希唯一来源 | 2、3、4 | lock 错误不变更目标或档案 |
| AC-06 安装回归 | 3、4、11、12 | 三平台安装生命周期与回滚 |
| AC-07 预览交互 | 7、8 | Node 测试与浏览器 checklist |
| AC-08 预览可追溯 | 5、6、8 | 当前版本证据、精确图集嵌入、未知规则禁用 |
| AC-09 动作评估 | 9、10 | 九行动作评估及修复闭环 |
| AC-10 素材回归 | 10、12 | 未改行像素一致／无修复时基线哈希相同 |
| AC-11 应用验证 | 12 | 实际观察或明确 NOT_RUN |
| AC-12 发布检查 | 11、12 | 同提交矩阵依赖、实际 CI 结果与发布边界 |

- **A（Task 1–4）：** 包与校验可独立交付；不因此宣称播放问题已解决。
- **B（Task 5–9）：** 已有可用诊断预览和评估；真实配置缺证据时保留禁用与缺口。
- **C（Task 10）：** 仅确认问题进入修复；跳过条件明确且可审计。
- **D（Task 11–12）：** 自动、浏览器和应用结果分别呈现；有缺口就保留未完成状态。

## 实施方式建议

推荐 **Native**：本计划的解析规则、素材身份和预览配置依赖较紧，由同一执行者顺序实现较少产生接口偏差；代码完成后安排一次独立整体审查。若 Boss 选择不使用独立 reviewer，按该明确指令执行并说明自审范围。

也可选择 **Subagent-driven**：按任务交付和审查，跨任务通过上述 Interfaces 对接，不让多个 agent 同时改同一契约文件。具体模型分配在执行方式选定后制定，并遵守 Global Constraints 中的模型／effort 上限。

本计划已获 Native 实施授权；未授权安装、合并、推送或发布。实施记录与未验收项见 qa/playback/v0.1.3/final-qa.md。
