---
title: 这是标题
shorttitle: 这是页眉标题
author:
- name: First Author
  affiliation: '1'
  corresponding: yes
  address: Postal address
  email: my@email.com
  role:
  - Conceptualization
  - Writing - Original Draft Preparation
  - Writing - Review & Editing
- name: Ernst-August Doelle
  affiliation: '1,2'
  role:
  - Writing - Review & Editing
  - Supervision
affiliation:
- id: '1'
  institution: Wilhelm-Wundt-University
- id: '2'
  institution: Konstanz Business School
authornote: |
  author note here.
keywords: bayesian; GLMM
floatsintext: no
figurelist: no
tablelist: no
footnotelist: no
linenumbers: yes
mask: no
draft: no
header-includes: |
  \makeatletter
  \renewcommand{\paragraph}{\@startsection{paragraph}{4}{\parindent}%
    {0\baselineskip \@plus 0.2ex \@minus 0.2ex}%
    {-1em}%
    {\normalfont\normalsize\bfseries\typesectitle}}

  \renewcommand{\subparagraph}[1]{\@startsection{subparagraph}{5}{1em}%
    {0\baselineskip \@plus 0.2ex \@minus 0.2ex}%
    {-\z@\relax}%
    {\normalfont\normalsize\bfseries\itshape\hspace{\parindent}{#1}\textit{\addperi}}{\relax}}
  \makeatother
zotero:
  library: BayesMultiTutorial-cn
  scannable_cite: no
  client: zotero
  author-in-text: no
  csl-style: apa
link-citations: yes
tblLabels: arabic
equationNumberTeX: 公式
eqnIndexTemplate: $$i$$
secPrefix: ''
figPrefix:
- 图
- 图
tblPrefix:
- 表
- 表
eqnPrefix:
- 公式
- 公式
citeproc: no
pandoc-crossref: yes
linkReferences: yes
nameInLink: yes
csl: D:/R/winR41/papaja/rmd/apa7.csl
documentclass: apa7
classoptions: doc
output:
  papaja::apa6_docx:
    pandoc_args:
    - --lua-filter=zotero.lua
    - -Fpandoc-crossref
    keep_md: yes

---



<div custom-style='Author'>
First Author^1^\ & Ernst-August Doelle^1,2^
</div>
<div custom-style='Author'>
^1^ Wilhelm-Wundt-University

^2^ Konstanz Business School
</div>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<div custom-style='Author'>
</div>


&nbsp;



&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;


<div custom-style='Author'>
Author note
</div>


author note here.


The authors made the following contributions. First Author: Conceptualization, Writing - Original Draft Preparation, Writing - Review & Editing; Ernst-August Doelle: Writing - Review & Editing, Supervision.

Correspondence concerning this article should be addressed to First Author, Postal address. E-mail: my@email.com


<div custom-style='h1-pagebreak'>Abstract</div>
这是摘要。

*Keywords:* bayesian; GLMM


<div custom-style='h1-pagebreak'>这是标题</div>







# 引入

$$ y = ax + c $$ {#eq:label}

测试引用文献：研究发现 [@adams2021; @kruschke2010]。 


公式 @eq:label 

\newpage

# References


