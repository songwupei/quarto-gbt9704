% ==================================================
%  gbt9704.cls  v2.0 20260706 
%  基于 memoir 文档类，符合 GB/T 9704-2012 公文格式标准
%  特性：大标宋红头、多附件、可选红色分割线、图表支持、标题缩进选项
%  修复：采用重定义章节命令方式强制标题缩进，确保在任何环境下生效
% ==================================================

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{gbt9704}[2026-07-06 v2.0 党政机关公文格式]

% ------------------ 自定义选项处理 ------------------
\newif\if@gbt@redline
\@gbt@redlinefalse
\newif\if@gbt@titleindent
\@gbt@titleindentfalse
\newif\if@gbt@zhlineskip
\@gbt@zhlineskipfalse

\DeclareOption{redline}{\@gbt@redlinetrue}
\DeclareOption{noredline}{\@gbt@redlinefalse}
\DeclareOption{titleindent}{\@gbt@titleindenttrue}
\DeclareOption{zhlineskip}{\@gbt@zhlineskiptrue}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{memoir}}
\ProcessOptions\relax

% ------------------ 基础设置 ------------------
\LoadClass[article, a4paper, 12pt, oneside]{memoir}

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

% ------------------ 中文支持 ------------------
\RequirePackage[UTF8, scheme=plain, heading=true, fontset=none]{ctex}

\newCJKfontfamily{\FangSongItalic}[AutoFakeSlant=0.2]{FangSong}
% 1.9增加20260415
% 伪粗体 伪斜体
\setCJKmainfont{FangSong}[
      AutoFakeBold=3.17,
      AutoFakeSlant=0.2,
]
\setCJKsansfont{SimHei}
\setCJKmonofont{Sarasa Mono SC}
\setmonofont{DejaVu Sans Mono}   % box-drawing 字符支持
\setCJKfamilyfont{zhfs}{FangSong}
\setCJKfamilyfont{zhkai}{KaiTi}
\setCJKfamilyfont{zhsong}{SimSun}          % 宋体备用
\setCJKfamilyfont{dabiaosong}{FZDaBiaoSong-B06}


% 定义 ctex 风格的字体切换命令
\newcommand{\heiti}{\sffamily}
\newcommand{\kaishu}{\CJKfamily{zhkai}}
\newcommand{\fangsong}{\CJKfamily{zhfs}}
\newcommand{\songti}{\CJKfamily{zhsong}}

\newcommand{\dabiaosong}{\CJKfamily{dabiaosong}}

% ------------------ 页面布局 ------------------
\setstocksize{297mm}{210mm}
\settrimmedsize{\stockheight}{\stockwidth}{*}
\settrims{0pt}{0pt}
\settypeblocksize{225mm}{156mm}{*}
\setlrmargins{28mm}{*}{1}
\setulmargins{37mm}{*}{1}
\checkandfixthelayout

\setcounter{secnumdepth}{0}

% ------------------ 段落格式（全局）------------------
\RequirePackage{indentfirst}  % 确保章节后第一段也缩进
\setlength{\parindent}{2em}
\setlength{\parskip}{0pt plus 0pt minus 0pt}
\setlength{\baselineskip}{28pt}
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
\RequirePackage{fcolumn}       % v1.5+ 财务表格：千分位分隔、小数点对齐、\sumline

\DeclareCaptionFont{sanhao}{\zihao{3}\fangsong}
\captionsetup{
    font=sanhao,
    labelsep=quad,
    justification=centering,
    singlelinecheck=false,
    skip=8pt,
}


% ------------------ 财务表格 (fcolumn) ------------------
% 提供便捷的财务表格列类型：
%   f  — 默认财务列：千分位 "."，小数点 ","，三位分组
%   自定义：F{<千分位>}{<小数位>}{<分组>}{<格式>}
%   示例：F{,}{.2}{{3}}{} → 1,234.56 样式（中文习惯）
%
% 便捷列类型：
%   C  — Chinese financial：逗号千分位，小数点，三位分组（1,234.56）
%        输入格式：150000.00（小数点作小数标记，逗号作千分位分隔）
\newcolumntype{C}{F,.{3.2}{}}
%   N  — 数字列（无千分位，两位小数，小数点对齐）
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
% 标题文本存储（pandoc 兼容：\title 存储，\maketitle 输出）
% 样式对齐 context-template: 大标宋、居中、二号字、28pt 行距
\let\@gongwentitle\@empty
\renewcommand{\title}[1]{\def\@gongwentitle{#1}}
\renewcommand{\maketitle}{%
  \ifx\@gongwentitle\@empty\else
    \gongwentitle{\@gongwentitle}
  \fi
}

% 公文大标题（版头后、主送前，始终顶格居中）
\newcommand{\gongwentitle}[1]{%
    \begingroup
    \zihao{2}
    \dabiaosong
    \setlength{\baselineskip}{28pt}
    \begin{center}
        #1\par
    \end{center}
    \endgroup
}% 公文副标题（紧随大标题之后，三号仿宋居中）
\newcommand{\gongwensubtitle}[1]{%
    \begingroup
    \zihao{3}           % 三号字（约16磅）
    \fangsong           % 仿宋体
    \setlength{\baselineskip}{28pt} % 可根据需要调整行距
    \begin{center}
        #1\par
    \end{center}
    \endgroup
}

% 1.9增加20260415
% 注释掉
% ========== 暴力重定义章节命令（强制缩进，确保万无一失）==========
% \if@gbt@titleindent
%   % 保存原始命令
%   \let\old@section\section
%   \let\old@subsection\subsection
%   \let\old@subsubsection\subsubsection
%   % 重定义：在标题文本前插入 2 个汉字的空白
%   \renewcommand{\section}[1]{%
%     \old@section{\hspace{2\ccwd}#1}\par
%   }
%   \renewcommand{\subsection}[1]{%
%     \old@subsection{\hspace{2\ccwd}#1}\par
%   }
%   \renewcommand{\subsubsection}[1]{%
%     \old@subsubsection{\hspace{2\ccwd}#1}\par
%   }
% \else
%   % 不缩进时，只需确保换行
%   \let\old@section\section
%   \let\old@subsection\subsection
%   \let\old@subsubsection\subsubsection
%   \renewcommand{\section}[1]{\old@section{#1}\par}
%   \renewcommand{\subsection}[1]{\old@subsection{#1}\par}
%   \renewcommand{\subsubsection}[1]{\old@subsubsection{#1}\par}
% \fi

% % 设置标题样式（字体、对齐等），注意：由于重定义了命令，这些样式仍会被应用
% \setsecheadstyle{\zihao{3}\kaiti\raggedright}
% \setsubsecheadstyle{\zihao{3}\kaiti\raggedright}
% \setsubsubsecheadstyle{\zihao{3}\normalfont\raggedright}

% 去掉默认间距
\setbeforesecskip{0pt}
\setaftersecskip{0pt}
\setbeforesubsecskip{0pt}
\setaftersubsecskip{0pt}
\setbeforesubsubsecskip{0pt}
\setaftersubsubsecskip{0pt}

% ------------------ 红头版头命令 ------------------
\newcommand{\makeheader}[3]{%
    \thispagestyle{gongwen}%
    \begin{center}
        \vspace*{1.2cm}
        \parbox{\textwidth}{%
            \centering
            \zihao{2}\dabiaosong\textcolor{chinese-red}{%
                \makebox[\textwidth][s]{#1}%
            }%
        }%
        \vspace{0.5cm}
        \parbox{\textwidth}{%
            \centering
            \zihao{-3}\songti #2 \\[0.2cm]
            \zihao{-3}\songti #3
        }%
        \vspace{0.5cm}
        \if@gbt@redline
            \textcolor{chinese-red}{\rule{\textwidth}{1.5pt}}
        \fi
        \vspace{0.3cm}
    \end{center}
}

% ------------------ 主送机关 ------------------
\newcommand{\mainreceiver}[1]{%
    \begingroup
    \zihao{3}
    \renewcommand{\baselineskip}{28pt}
    \noindent #1\par
    \endgroup
}




% ------------------ 附件处理（单附件与多附件统一缩进）------------------
% 单附件命令：独立段落，自动首行缩进
% 前面加附件：
\newcommand{\attachmentHZ}[1]{%
    \par
    \vspace{0.3cm}
    \begingroup
        \zihao{3}\fangsong
        \setlength{\baselineskip}{28pt}
        \setlength{\parindent}{2\ccwd}
        \setlength{\parskip}{0pt}
        附件：#1\par
    \endgroup
}
% 前面不加附件：
\newcommand{\attachmentNOHZ}[1]{%
    \par
    \vspace{0.3cm}
    \begingroup
        \zihao{3}\fangsong
        \setlength{\baselineskip}{28pt}
        \setlength{\parindent}{5\ccwd}
        \setlength{\parskip}{0pt}
        #1\par
    \endgroup
}
 

% ------------------ 附件处理（多附件自动对齐，首项紧跟“附件：”）------------------

\newenvironment{attachments}{%
    \par
    \vspace{0.3cm}
    \zihao{3}\fangsong
    \setlength{\baselineskip}{28pt}
    \setlength{\parindent}{2\ccwd}
    \setlength{\parskip}{0pt}
    \noindent\hspace{2\ccwd}附件：%
}{%
    \par
}


\newcommand{\attachmentitem}[2][4.9]{% 可选参数控制缩进量（默认4.9）
    \par
    \vspace{0.3cm}
    \noindent
    \hspace*{#1\ccwd}%
    \parbox[t]{\dimexpr\linewidth-#1\ccwd\relax}{%
        \setlength{\baselineskip}{28pt}%
        #2\strut
    }\par
}

% ------------------ 发文机关署名 ------------------
\newcommand{\signature}[1]{%
    \begingroup
    \zihao{3}
    \setlength{\baselineskip}{28pt}
    \begin{flushright}
        #1\hspace{2\ccwd}
    \end{flushright}
    \endgroup
}

% ------------------ 成文日期 ------------------
\newcommand{\signdate}[1]{%
    \begingroup
    \zihao{3}
    \setlength{\baselineskip}{28pt}
    \begin{flushright}
        #1\hspace{2\ccwd}
    \end{flushright}
    \endgroup
}

% ------------------ 附注 ------------------
\newcommand{\notes}[1]{%
    \begingroup
    \zihao{3}
    \setlength{\baselineskip}{28pt}
    \noindent （#1）\par
    \endgroup
}

% ------------------ 版记分隔线 ------------------
\newcommand{\seprule}{%
    \noindent\rule{\textwidth}{0.5pt}\par
}

% ------------------ 抄送机关 ------------------
\newcommand{\copyto}[1]{%
    \begingroup
    \zihao{3}
    \setlength{\baselineskip}{28pt}
    \noindent 抄送：#1\par
    \endgroup
}

% ------------------ 印发机关和印发日期 ------------------
\newcommand{\issueinfo}[2]{%
    \begingroup
    \zihao{3}
    \setlength{\baselineskip}{28pt}
    \noindent #1\hfill #2\par
    \endgroup
}

% ------------------ 正文环境 ------------------
\newenvironment{gongwenbody}{%
    \zihao{3}
    \setlength{\baselineskip}{28pt}
    \setlength{\parindent}{2\ccwd}
    \setlength{\parskip}{0pt}
}{}

% ------------------ 页码格式 ------------------
\makepagestyle{gongwen}
\makeevenfoot{gongwen}{\zihao{4}\thepage}{}{}
\makeoddfoot{gongwen}{}{}{\zihao{4}\thepage}
\makeevenhead{gongwen}{}{}{}
\makeoddhead{gongwen}{}{}{}
\pagestyle{gongwen}

% ------------------ emoji 支持 ------------------
% 提供 \emoji{} 命令以便 Pandoc Lua filter 调用
% 多字体回退策略（按优先级）：
%   1. Segoe UI Emoji — COLRv0 彩色矢量，基础轮廓有实体，XeTeX 剥离 COLR 后仍可黑白渲染
%      （Windows / WPS 自带；v1.29+ 覆盖完整包括 🗂️📞📧）
%   2. NotoEmoji-Regular — B&W 轮廓字体，TeX Live noto-emoji 包自带
%
% 注意：Noto Color Emoji COLRv1 不适用于 XeTeX！
%   XeTeX 的 CID 字体嵌入会剥离 COLR/CPAL 表，而 COLRv1 字形的 glyf 轮廓为 0-contours
%   （完全依赖 COLR 层），导致 emoji 不可见。如需彩色 emoji，请使用 LuaHBTeX。
\IfFontExistsTF{Segoe UI Emoji}{%
  \newfontfamily{\gbtemojifont}{Segoe UI Emoji}[Scale=MatchUppercase]%
}{%
  \newfontfamily{\gbtemojifont}{NotoEmoji-Regular.ttf}[Extension=.ttf, Scale=MatchUppercase]%
}
\newcommand{\emoji}[1]{{\gbtemojifont #1}}

% ------------------ 辅助命令 ------------------
\newcommand{\setgongwenlinespread}{%
    \setlength{\baselineskip}{28pt}
}



\AtBeginDocument{%
    % --- 确保 monofont 在 lmodern 等模板包之后仍生效 ---
    \setmonofont{DejaVu Sans Mono}%
    % --- 全局正文字体、行距、缩进 ---
    \zihao{3}%
    \setlength{\baselineskip}{28pt}%
    \setlength{\parindent}{2\ccwd}%
    \setlength{\parskip}{0pt}%
    % --- 清零章节间距 ---
    \setlength{\beforesecskip}{0pt}
    \setlength{\aftersecskip}{0pt}
    \setlength{\beforesubsecskip}{0pt}
    \setlength{\aftersubsecskip}{0pt}
    \setlength{\beforesubsubsecskip}{0pt}
    \setlength{\aftersubsubsecskip}{0pt}
    % --- 二级标题（##）：楷体加粗，首行缩进2字符 ---
    \let\oldsubsection\subsection
    \renewcommand{\subsection}[1]{%
        \oldsubsection{%
            \zihao{3}\kaishu\bfseries
            \hspace*{2\ccwd}#1%
        }\par
    }%
    % --- 三级标题（###）：仿宋加粗，首行缩进2字符 ---
    \let\oldsubsubsection\subsubsection
    \renewcommand{\subsubsection}[1]{%
        \oldsubsubsection{%
            \zihao{3}\normalfont\bfseries
            \hspace*{2\ccwd}#1%
        }\par
    }%
    % --- 一级标题（#）：黑体，首行缩进2字符 ---
    \let\oldsection\section
    \renewcommand{\section}[1]{%
        \oldsection{%
            \zihao{3}\heiti
            \hspace*{2\ccwd}#1%
        }\par
    }%
    % --- 修复 soul 包对 CJK 不兼容：重定义 \st \ul 为 ulem 版本 ---
    \@ifpackageloaded{soul}{%
      \renewcommand{\st}[1]{\sout{#1}}%
      \renewcommand{\ul}[1]{\uline{#1}}%
    }{%
      \providecommand{\st}[1]{\sout{#1}}%
      \providecommand{\ul}[1]{\uline{#1}}%
    }%
}
\endinput
