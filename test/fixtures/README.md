# test/fixtures

## `etrip_test_font_cjk.ttf`

一份中文字库，**只给 golden 测试用**。不在 `pubspec.yaml` 里，不进 App，不进 CI。

没有它，golden 图里的中文会全变成方框——flutter_test 自带的字体没有汉字，
`Icon` 用的图标字体也不会加载，看基准图等于看一排 `□`，出了问题发现不了。

### 它是什么

从 Noto Sans CJK SC 里切出来的一个子集：

| 项 | 值 |
| --- | --- |
| 来源 | Noto Sans CJK SC（`NotoSansCJK-Regular.ttc`，face 2） |
| 版本 | 2.004 |
| 授权 | SIL Open Font License 1.1 |
| 收录 | ASCII 可打印字符 + `lib/` `test/` 里出现过的所有字符 |
| 字形数 | 2092（cmap 1174） |
| 大小 | ~530 KB |

### 为什么要是 TrueType（glyf）而不是原始的 OTF/CFF

原始的 Noto Sans CJK 是 CID-keyed CFF 字体。flutter_test 的渲染器画不了这种字
里的汉字，会出豆腐块——**连提取出单个 face 也一样**，不是子集切的锅。用
`otf2ttf` 把三次贝塞尔转成二次（glyf 表）就好了。

顺带一提，系统里的 `DroidSansFallbackFull.ttf` 本来就是 glyf，中文能画，但它
**没有拉丁字形**，拿它当唯一的 golden 字体，英文会全变方框。

### 怎么重新生成

改过页面文案、golden 里新出现的中文变成方框了，就重跑一遍：

```bash
cd Etrip
pip install --break-system-packages fonttools otf2ttf

# 1. 收集字符：lib/ 和 test/ 里的所有字符，加上 ASCII 可打印字符
python3 - <<'EOF'
import pathlib
chars = set()
for p in list(pathlib.Path('lib').rglob('*.dart')) + list(pathlib.Path('test').rglob('*.dart')):
    chars.update(p.read_text(encoding='utf-8'))
chars.update(chr(c) for c in range(0x20, 0x7f))   # ← 空格在这里，别漏
open('/tmp/chars.txt', 'w', encoding='utf-8').write(''.join(sorted(chars)))
EOF

# 2. 切子集（--font-number=2 就是 Noto Sans CJK SC）
pyftsubset /usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc \
  --font-number=2 --text-file=/tmp/chars.txt --output-file=/tmp/subset.otf

# 3. CFF -> glyf
otf2ttf /tmp/subset.otf -o test/fixtures/etrip_test_font_cjk.ttf

# 4. 字变了，基准图得重出，然后**打开图看一眼**
flutter test test/golden --update-goldens
```

`otf2ttf` 用 pip 装的话在 `~/.local/bin/otf2ttf`，不在 PATH 里就写全路径。

第 1 步里那个 `chr(0x20)` 不是凑数：字符集里一旦漏掉空格，空格就没有字形，
渲染时会退回测试字体那个特别宽的空格，整页拉丁文全部被撑开——基准图看着
"就是字距怪怪的"，很容易当成字体问题查半天。
