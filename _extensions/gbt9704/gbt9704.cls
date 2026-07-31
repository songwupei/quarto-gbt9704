% ==================================================
%  gbt9704.cls  v0.1.10 20260730
%  SPDX-License-Identifier: LPPL-1.3c
%  基于 memoir 文档类，符合 GB/T 9704-2012 公文格式标准
%  支持 LuaLaTeX（推荐，彩色 emoji）和 XeLaTeX（字体回退）
%  新增 fzfonts 选项：方正商用字体预设（小标宋/仿宋/黑体）
% ==================================================

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{gbt9704}[2026-07-30 v0.1.10 GB/T 9704-2012 Document Class]

% ------------------ 引擎检测 ------------------
\RequirePackage{iftex}
\ifLuaTeX\else
  \ClassWarning{gbt9704}{LuaLaTeX is recommended. Colored emoji requires LuaLaTeX+Harfbuzz.}
\fi

% ------------------ 选项处理 ------------------
\newif\if@gbt@redline
\@gbt@redlinefalse
\newif\if@gbt@titleindent
\@gbt@titleindenttrue  % 默认开启缩进（符合国标）
\newif\if@gbt@zhlineskip
\@gbt@zhlineskipfalse
\newif\if@gbt@emoji
\@gbt@emojitrue
\newif\if@gbt@fzfonts
\@gbt@fzfontsfalse  % 默认使用 fallback 开源字体

\DeclareOption{redline}{\@gbt@redlinetrue}
\DeclareOption{noredline}{\@gbt@redlinefalse}
\DeclareOption{titleindent}{\@gbt@titleindenttrue}
\DeclareOption{notitleindent}{\@gbt@titleindentfalse}
\DeclareOption{zhlineskip}{\@gbt@zhlineskiptrue}
\DeclareOption{emoji}{\@gbt@emojitrue}
\DeclareOption{noemoji}{\@gbt@emojifalse}
\DeclareOption{fzfonts}{\@gbt@fzfontstrue}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{memoir}}
\ProcessOptions\relax

% ------------------ 基础类与中文 ------------------
\LoadClass[article, a4paper, 12pt, oneside]{memoir}
\RequirePackage[UTF8, scheme=plain, heading=true, fontset=none]{ctex}

% ------------------ zhlineskip 行距支持 ------------------
% GB/T 9704 要求正文三号（16pt）行距 28pt
%   bodytextleadingratio = 28pt / 16pt = 1.75
%   footnoteleadingratio 与正文保持一致
%   数学公式恢复西文行距（restoremathleading）
\if@gbt@zhlineskip
  \RequirePackage[
    bodytextleadingratio = 1.75,
    footnoteleadingratio = 1.75,
    restoremathleading,
    quiet
  ]{zhlineskip}
\fi

% ------------------ 字体设置 ------------------
\RequirePackage{fontspec}

\if@gbt@fzfonts
  % ================================================================
  % fzfonts — 方正商用字体方案
  % 匹配西文：Times New Roman（衬线）、Arial（无衬线）、Consolas（等宽）
  % 数学字体：newtxmath（与 Times 完美匹配）
  % ================================================================

  % --- 红头字体：方正小标宋简体 → 方正小标宋_GBK → 大标宋 → SimHei ---
  \IfFontExistsTF{FZXiaoBiaoSong-B05S}{
    \setCJKfamilyfont{xiaobiaosong}{FZXiaoBiaoSong-B05S}
  }{
    \IfFontExistsTF{FZXiaoBiaoSong-B05}{
      \setCJKfamilyfont{xiaobiaosong}{FZXiaoBiaoSong-B05}
      \ClassWarning{gbt9704}{FZXiaoBiaoSong-B05S not found, using FZXiaoBiaoSong-B05}
    }{
      \IfFontExistsTF{FZDaBiaoSong-B06}{
        \setCJKfamilyfont{xiaobiaosong}{FZDaBiaoSong-B06}
        \ClassWarning{gbt9704}{FangZheng XiaoBiaoSong not found, using FZDaBiaoSong-B06}
      }{
        \setCJKfamilyfont{xiaobiaosong}{SimHei}[AutoFakeBold=*]
        \ClassWarning{gbt9704}{FangZheng XiaoBiaoSong/DaBiaoSong not found, using SimHei}
      }
    }
  }

  % --- 主字体：方正仿宋 ---
  \setCJKmainfont{FZFangSong-Z02}[AutoFakeBold=3.17, AutoFakeSlant=0.2]
  \setCJKsansfont{FZHei-B01}[Scale=1]  % 锁定 Scale，防止 unicode-math 全局缩放
  \setCJKfamilyfont{zhfs}{FZFangSong-Z02}
  \setCJKfamilyfont{zhkai}{FZKai-Z03}
  \setCJKfamilyfont{zhsong}{FZShuSong-Z01}

  % --- 西文：Times New Roman 系 ---
  \setmainfont{Times New Roman}
  \setsansfont{Arial}
  \setmonofont{Consolas}

  % --- 数学字体 ---
  % LuaLaTeX 下 newtxmath 可能冲突，公文场景极少数学公式
  % 使用默认 Latin Modern Math（与 Times New Roman 的 x-height 接近）
  \IfFileExists{amsmath.sty}{\RequirePackage{amsmath}}{}

  % --- 字体切换命令 ---
  \newcommand{\gbt@redheadfont}{\CJKfamily{xiaobiaosong}}
  \newcommand{\heiti}{\sffamily}
  \newcommand{\kaishu}{\CJKfamily{zhkai}}
  \newcommand{\fangsong}{\CJKfamily{zhfs}}
  \newcommand{\songti}{\CJKfamily{zhsong}}
  \newcommand{\dabiaosong}{\CJKfamily{xiaobiaosong}}

\else
  % ================================================================
  % fallback — 开源/系统字体方案（默认）
  % 匹配西文：LMRoman（Latin Modern）
  % ================================================================

  % --- 红头字体：方正大标宋 → SimHei ---
  \IfFontExistsTF{FZDaBiaoSong-B06}{
    \setCJKfamilyfont{dabiaosong}{FZDaBiaoSong-B06}
  }{
    \setCJKfamilyfont{dabiaosong}{SimHei}[AutoFakeBold=*]
    \ClassWarning{gbt9704}{FZDaBiaoSong-B06 not found, using SimHei as fallback}
  }

  % --- 主字体：仿宋 ---
  \setCJKmainfont{FangSong}[AutoFakeBold=3.17, AutoFakeSlant=0.2]
  \setCJKsansfont{SimHei}[Scale=1]  % 锁定 Scale，防止 unicode-math 全局缩放
  \setCJKfamilyfont{zhfs}{FangSong}
  \setCJKfamilyfont{zhkai}{KaiTi}
  \setCJKfamilyfont{zhsong}{SimSun}

  % --- 等宽字体 ---
  \setCJKmonofont{Sarasa Mono SC}
  \setmonofont{DejaVu Sans Mono}

  % --- 字体切换命令 ---
  \newcommand{\gbt@redheadfont}{\CJKfamily{dabiaosong}}
  \newcommand{\heiti}{\sffamily}
  \newcommand{\kaishu}{\CJKfamily{zhkai}}
  \newcommand{\fangsong}{\CJKfamily{zhfs}}
  \newcommand{\songti}{\CJKfamily{zhsong}}
  \newcommand{\dabiaosong}{\CJKfamily{dabiaosong}}

\fi

% --- 跨主题通用 ---
% 仿宋斜体（用于强调）
\newCJKfontfamily{\FangSongItalic}[AutoFakeSlant=0.2]{FangSong}

% ------------------ 彩色 Emoji 支持（双引擎） ------------------
% LuaLaTeX：bxcoloremoji → twemojis 渲染管线，输出 PDF 彩色矢量图形
% XeLaTeX：Segoe UI Emoji / NotoEmoji 字体回退（COLRv0 剥离后黑白渲染）
\if@gbt@emoji
  \ifLuaTeX
    \IfFileExists{bxcoloremoji.sty}{%
      \RequirePackage{bxcoloremoji}
      % Lua 辅助函数：十进制 Unicode 码点 → 十六进制字符串
      \directlua{
        function gbt_cp2hex(cp)
          local h = string.format("\@percentchar X", cp)
          tex.sprint(h)
        end
      }
    }{%
      \ClassWarning{gbt9704}{bxcoloremoji package not found. Install via: tlmgr install bxcoloremoji}
      \@gbt@emojifalse
    }
  \else
    % XeLaTeX / other：字体回退
    % Segoe UI Emoji — COLRv0 彩色矢量，基础轮廓有实体，XeTeX 剥离 COLR 后仍可黑白渲染
    % NotoEmoji-Regular — B&W 轮廓字体，TeX Live noto-emoji 包自带
    \IfFontExistsTF{Segoe UI Emoji}{%
      \newfontfamily{\gbtemojifont}{Segoe UI Emoji}[Scale=MatchUppercase]%
    }{%
      \newfontfamily{\gbtemojifont}{NotoEmoji-Regular.ttf}[Extension=.ttf, Scale=MatchUppercase]%
    }
  \fi
\fi

% 用户命令：\emoji{<Unicode 字符>}
\if@gbt@emoji
  \ifLuaTeX
    % LuaLaTeX：bxcoloremoji 彩色矢量渲染
    % 多码点序列（ZWJ、肤色修饰、VS16 等）只取首字符码点，其余丢弃
    \def\gbt@emoji@getfirst#1#2\gbt@emoji@end{%
      \edef\@gbt@emoji@cp{\number`#1}%
      \edef\@gbt@emoji@hex{\directlua{gbt_cp2hex(\@gbt@emoji@cp)}}%
      \ifx\@gbt@emoji@hex\@empty
        \ClassWarning{gbt9704}{Emoji conversion failed}%
        [#1#2]%
      \else
        \expandafter\coloremojicode\expandafter{\@gbt@emoji@hex}%
      \fi
    }
    \newcommand{\emoji}[1]{%
      \gbt@emoji@getfirst#1\gbt@emoji@end
    }
  \else
    % XeLaTeX / other：字体回退渲染（天然支持多码点序列）
    \newcommand{\emoji}[1]{{\gbtemojifont #1}}
  \fi
\else
  \newcommand{\emoji}[1]{%
    \ClassWarning{gbt9704}{Emoji not available: \detokenize{#1}}%
    [#1]%
  }
\fi

% ------------------ 页面布局 ------------------
\setstocksize{297mm}{210mm}
\settrimmedsize{\stockheight}{\stockwidth}{*}
\settrims{0pt}{0pt}
\settypeblocksize{225mm}{156mm}{*}
\setlrmargins{28mm}{*}{1}
\setulmargins{37mm}{*}{1}
\checkandfixthelayout

\setcounter{secnumdepth}{0}

% ------------------ 段落格式（全局） ------------------
\RequirePackage{indentfirst}  % 确保章节后第一段也缩进
\setlength{\parindent}{2em}
\setlength{\parskip}{0pt plus 0pt minus 0pt}
\setlength{\baselineskip}{28pt}

% CJK 断行优化
\hyphenpenalty=10000
\tolerance=1000
\emergencystretch=\maxdimen

\RequirePackage[normalem]{ulem}  % CJK 安全的删除线（替代 soul）
\RequirePackage{alltt}           % alltt 环境 — 保留空白且支持 \emoji{} 命令

% ------------------ 颜色定义 ------------------
\RequirePackage{xcolor}
\definecolor{chinese-red}{RGB}{200,16,46}

% ------------------ 表格与图片支持 ------------------
\RequirePackage{graphicx}
\RequirePackage{array}
\RequirePackage{booktabs}
\RequirePackage{longtable}
\RequirePackage{caption}
\RequirePackage{subcaption}
\RequirePackage{fcolumn}       % 财务表格：千分位分隔、小数点对齐、\sumline

\DeclareCaptionFont{sanhao}{\zihao{3}\fangsong}
\captionsetup{
    font=sanhao,
    labelsep=quad,
    justification=centering,
    singlelinecheck=false,
    skip=8pt,
}

% ------------------ 财务表格 (fcolumn) ------------------
% 便捷列类型：
%   C  — Chinese financial：逗号千分位，小数点，三位分组（1,234.56）
%   N  — 数字列（无千分位，两位小数，小数点对齐）
\newcolumntype{C}{F,.{3.2}{}}
\newcolumntype{N}{F{}{.2}{}{}}

% 财务表格环境：自动重置 sumline 计数器
\newenvironment{financialtable}[1]{%
  \zihao{3}\fangsong
  \setlength{\baselineskip}{28pt}
  \resetsumline
  \begin{tabular}{#1}
}{%
  \end{tabular}
}

% ------------------ 标题格式 ------------------
% pandoc 兼容：\title 存储，\maketitle 输出
% 样式：大标宋、居中、二号字、28pt 行距
\let\@gongwentitle\@empty
\renewcommand{\title}[1]{\def\@gongwentitle{#1}}
\renewcommand{\maketitle}{%
  \ifx\@gongwentitle\@empty\else
    \gongwentitle{\@gongwentitle}
  \fi
}

% 公文大标题（版头后、主送前，始终顶格居中）
% 使用当前字体主题的红头字体（与 \makeheader 一致）
\newcommand{\gongwentitle}[1]{%
  \begingroup\zihao{2}\gbt@redheadfont\setlength{\baselineskip}{28pt}
  \begin{center}#1\par\end{center}\endgroup
}

% 公文副标题（紧随大标题之后，三号仿宋居中）
\newcommand{\gongwensubtitle}[1]{%
  \begingroup\zihao{3}\fangsong\setlength{\baselineskip}{28pt}
  \begin{center}#1\par\end{center}\endgroup
}

% ------------------ 章节格式（ctex 原生接口，heading=true 兼容） ------------------
\setbeforesecskip{0pt}\setaftersecskip{0pt}
\setbeforesubsecskip{0pt}\setaftersubsecskip{0pt}
\setbeforesubsubsecskip{0pt}\setaftersubsubsecskip{0pt}

\AtBeginDocument{%
  \zihao{3}\setlength{\baselineskip}{28pt}%
  \setlength{\parindent}{2\ccwd}%

  % 确保 monofont 在 lmodern 等模板包之后仍生效
  \setmonofont{DejaVu Sans Mono}%

  % 标题样式（使用 ctex 原生接口，heading=true 时正确生效）
  \ctexset{
    section = {
      format = \zihao{3}\heiti\raggedright,
      beforeskip = 0pt,
      afterskip = 0pt,
    },
    subsection = {
      format = \zihao{3}\kaishu\bfseries\raggedright,
      beforeskip = 0pt,
      afterskip = 0pt,
    },
    subsubsection = {
      format = \zihao{3}\normalfont\bfseries\raggedright,
      beforeskip = 0pt,
      afterskip = 0pt,
    },
  }
  % 标题缩进控制
  \if@gbt@titleindent
    \ctexset{
      section/indent = 2\ccwd,
      subsection/indent = 2\ccwd,
      subsubsection/indent = 2\ccwd,
    }
  \else
    \ctexset{
      section/indent = 0pt,
      subsection/indent = 0pt,
      subsubsection/indent = 0pt,
    }
  \fi

  % 修复 soul 包对 CJK 不兼容：重定义 \st \ul 为 ulem 版本
  \@ifpackageloaded{soul}{%
    \renewcommand{\st}[1]{\sout{#1}}%
    \renewcommand{\ul}[1]{\uline{#1}}%
  }{%
    \providecommand{\st}[1]{\sout{#1}}%
    \providecommand{\ul}[1]{\uline{#1}}%
  }%
}

% ------------------ 公文组件命令 ------------------

% 红头版头
% #1 = 发文机关（自动使用当前字体主题的红头字体）
% #2 = 发文字号
% #3 = 签发人（可选，留空则不显示）
\newcommand{\makeheader}[3]{%
  \thispagestyle{gongwen}%
  \begin{center}\vspace*{1.2cm}
    \parbox{\textwidth}{\centering\zihao{0}\gbt@redheadfont\textcolor{chinese-red}{\scalebox{0.75}[1]{#1}}}%
    \vspace{0.5cm}
    \parbox{\textwidth}{\centering\zihao{3}\fangsong #2 \\[0.2cm] \zihao{3}\fangsong #3}%
    \vspace{0.1cm}
    \if@gbt@redline\textcolor{chinese-red}{\rule{\textwidth}{1.5pt}}\fi
    \vspace{0.3cm}
  \end{center}
}

% 主送机关
\newcommand{\mainreceiver}[1]{%
  \begingroup\zihao{3}\setlength{\baselineskip}{28pt}\noindent #1\par\endgroup
}

% 单附件（带"附件："前缀）
% 按 GB/T 9704-2012 7.3.4，正文下空一行编排"附件"
\newcommand{\attachmentHZ}[1]{%
  \par\vspace{\baselineskip}\begingroup\zihao{3}\fangsong
  \setlength{\baselineskip}{28pt}\setlength{\parindent}{2\ccwd}
  附件：#1\par\endgroup
}

% 单附件（不带"附件："前缀，适用于附件列表中的条目）
\newcommand{\attachmentNOHZ}[1]{%
  \par\begingroup\zihao{3}\fangsong
  \setlength{\baselineskip}{28pt}\setlength{\parindent}{5\ccwd}
  #1\par\endgroup
}

% 多附件环境
% 首个附件项前空一行（\baselineskip），后续项自然衔接无额外间距
\newenvironment{attachments}{%
  \par\vspace{\baselineskip}\zihao{3}\fangsong\setlength{\baselineskip}{28pt}%
  \setlength{\parindent}{2\ccwd}\noindent\hspace{2\ccwd}附件：%
}{\par}

% 多附件条目（可选参数控制缩进量，默认 4.9\ccwd）
% 附件条目之间使用自然行距（28pt），无额外段间距
\newcommand{\attachmentitem}[2][4.9]{%
  \par\noindent\hspace*{#1\ccwd}%
  \parbox[t]{\dimexpr\linewidth-#1\ccwd\relax}{\setlength{\baselineskip}{28pt}#2\strut}\par
}

% 发文机关署名
\newcommand{\signature}[1]{%
  \begingroup\zihao{3}\setlength{\baselineskip}{28pt}\flushright #1\hspace{2\ccwd}\endflushright\endgroup
}

% 成文日期
\newcommand{\signdate}[1]{%
  \begingroup\zihao{3}\setlength{\baselineskip}{28pt}\flushright #1\hspace{2\ccwd}\endflushright\endgroup
}

% 附注
\newcommand{\notes}[1]{%
  \begingroup\zihao{3}\setlength{\baselineskip}{28pt}\noindent （#1）\par\endgroup
}

% 版记分隔线
\newcommand{\seprule}{\noindent\rule{\textwidth}{1pt}\par}

% 抄送机关
\newcommand{\copyto}[1]{%
  \begingroup\zihao{4}\setlength{\baselineskip}{28pt}\noindent 抄送：#1\par\endgroup
}

% 印发机关和印发日期
\newcommand{\issueinfo}[2]{%
  \begingroup\zihao{4}\setlength{\baselineskip}{28pt}\noindent #1\hfill #2\par\endgroup
}

% ------------------ 正文环境 ------------------
\newenvironment{gongwenbody}{%
  \zihao{3}
  \setlength{\baselineskip}{28pt}
  \setlength{\parindent}{2\ccwd}
  \setlength{\parskip}{0pt}
}{}

% ------------------ 辅助命令 ------------------
\newcommand{\setgongwenlinespread}{%
  \setlength{\baselineskip}{28pt}
}

% ------------------ 页码格式 ------------------
\makepagestyle{gongwen}
\makeevenfoot{gongwen}{\zihao{4}\songti\ —\ \thepage\ —}{}{}
\makeoddfoot{gongwen}{}{}{\zihao{4}\songti\ —\ \thepage\ —}
\makeevenhead{gongwen}{}{}{}\makeoddhead{gongwen}{}{}{}
\pagestyle{gongwen}

\endinput
