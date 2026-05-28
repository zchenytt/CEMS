\documentclass[11pt]{article}
\usepackage[a4paper,margin=1in]{geometry}
% \usepackage[a4paper,margin=0.1in]{geometry}
\usepackage{amsmath,amssymb}
\usepackage[dvipsnames]{xcolor}
\usepackage{hyperref}
\usepackage{enumitem}

\newcommand{\sect}[1]{\textbf{Section}~\ref{#1}}
\newcommand{\faq}[1]{\textbf{FAQ}~\ref{#1}}
\newcommand{\rtwo}[1]{\textbf{R2}~\ref{#1}}
\newcommand{\blue}[1]{\textcolor{blue}{#1}}

\begin{document}
\begin{center}
    {\Large \textbf{Response Letter}}\\[1ex]
    \textbf{Manuscript ID:} TSG-02572-2025\\
    \textbf{Title:} ``A Distributed Multi-Energy Optimal Coordination Scheme Exploiting Neighborhood Flexibility''
\end{center}

We sincerely thank you for your careful reading of the manuscript and the detailed comments.
\par
In order to reduce duplicate texts thus providing a clean reading experience, we've made use of\footnote{Otherwise there would be repetitions which would make this file much more cumbersome.} cross references in this file.
So it perhaps is a better experience to read this file on electronic devices
as click-and-jump can function\footnote{Note there is also a built-in `Table of Contents' with this file.}.
For example, `R2-1' means `the 1st item in Section~\textbf{R2}', while `\textbf{FAQ} 2' means `the 2nd item in Section~\textbf{FAQ}'.
\par
If a \blue{modification} to the manuscript has been made, we would display them in \blue{blue} color\footnote{Details are seen in the PDF with tracked changes, wherein the newly added texts are also in blue color.}. Otherwise, we will expound the reason why we decide not to revise along the reviewers' idea.
\par
We hope that our revisions have properly addressed your concerns.
Please let us know if any issues remain that require further clarification.

\section{E1-Question (answered in \sect{e1ans})}
While appreciating the potential value of this finding, reviewers have provided a number of constructive and professional suggestions/comments for improving the paper, such as theoretical analysis, presentation and simulation, etc. Note that, although one of the reviewers lists some references in her/his comments, authors are not obliged to use any references (e.g. conference articles, journal articles or reports, etc.) recommended by reviewers. In fact, authors are fully within their rights to reject such a suggestion outright unless the authors feel that the suggested references add materially to the content and or quality of the submission. In my point of view, however, the authors do need to pay attention to the following aspects, which may critically influence the decision in the next round:
\begin{enumerate}
    \item Rigorous presentation and explanation of the core algorithm.
    \item Theoretical results of the proposed algorithm, such as convergence proof and efficiency analysis, rather than listing simulation tests alone.
    \item Comparison against state-of-the-art distributed algorithms (particularly asynchronous ones), both in the literature review and the simulation study.
    \item Discussion on robustness in imperfect communication conditions.
    \item Justification of the asynchronous setting of the problem, especially how it is simulated in your case study and how it fits the engineering practice.
    \item In-depth analysis of the mechanism of the efficiency and effectiveness of the core algorithm.
\end{enumerate}

\section{E1} \label{e1ans}
Thanks for your careful reading and constructive comments. We hope the following reply clarifies your concern.
\begin{enumerate}
    \item answered in R2-\ref{remainsvague}
    \item answered in R5-\ref{r5_4}
    \item answered in R2-\ref{like19}, R5-\ref{r5_1}, R4-\ref{blockdecompocite}
    \item answered in R2-\ref{r2_4}
    \item answered in R1-\ref{fitness}, R2-\ref{remainsvague}.
    \item We believe that the above items had addressed many aspects.
    In the current revision, \blue{we've strengthened the theoretical foundation} (e.g. convex analysis details Eq.(34)) that supports Section IV's algorithm design.
    The effective and efficient behavior is observed in our numerical simulation, both in terms of the training time (hardware-dependent, Fig.~4--5) and the number of cuts (not hardware-dependent, Fig.~6).
    \par
    Since our method is relatively new and there are some theoretical hurdles to be overcome in our asynchronous multithreaded setting (e.g. \faq{notadmm}\faq{noconverge}\faq{noiteration}), we did not go further to add more details.
    If possible, we hope to address it in future studies.
\end{enumerate}

\section{R1-Question (answered in \sect{r1ans})}
This paper proposes a decentralized scheme for coordinating multi-energy consumption in a residential neighborhood, in which the effect of social contacts between pairs of households are taken into account. This research is valuable for smart gird. Some concerns are as follows.
\begin{enumerate}
    \item Motivations in Introduction should be further highlighted.
    \item It is suggested that the author should list all constants and decision variables.
    \item Provide a comparison table of your review section is needed.
    \item Authors should provide detailed simulation results.
    \item It is suggested that the author include comparisons with other algorithms in computational experiments.
    \item How does this article address the fluctuations in energy demand and supply in real-life situations? Especially in cases where there is renewable energy?
    \item Detailed comparisons with other algorithms are necessary. Moreover, please discuss the advantages of the proposed algorithm?
    \item It is suggested that the author discuss the scalability of the model.
    \item It is suggested that the author demonstrate the robustness and economy of the algorithm.
    \item Authors should further refine the paper.
    \item Case study cannot be recognized as a contribution.
    \item The case data should be made available online.
\end{enumerate}

\section{R1} \label{r1ans}
Thanks for your careful reading and constructive comments. We hope the following reply clarifies your concern.
\begin{enumerate}
    \item The 2nd paragraph (motivations) \blue{has been revised}.
    \item This concerns Section II. It is indeed important to distinguish input parameters (which you referred to as `constants') and decision variables for an optimization model. But after reassessing our manuscript we think the current layout is already visually clean for the readers. The physical model is only confined in Section II. Decision variables are in lower case, \textit{italic} whereas parameters are UPRIGHT. The physical meaning of each equation has been explained so there is no redundancy. We have yet another advantage that our model is a standard MILP---it's linear, e.g. every term is like `$\mathrm{C_t}p_t$', where $\mathrm{C}_t$ is nothing but the coefficient of $p_t$. So there is basically no room for misunderstanding.
    \item Thanks for the suggestion. We see that in some mature field, authors tend to insert a table because there are many comparative papers
    (e.g. for a microgrid component modeling paper where there are a lot of existing modeling methods). However, we are not aware of a
    sufficient amount of papers similar to our setting (e.g. see R5-\ref{r5_1}). On the other hand, plain words are always more flexible, concise and accurate. I think the distinctive features of this research are already expressed openly in the revised manuscript, e.g. making proper use of asynchronous programming in numeric simulation, global optimization with valid bounds etc.
    \item Yes, they are presented in the revised paper.
    \item see \faq{compare}
    \item Energy demand trajectory in this paper is deemed an input, which is nonrandom---we are not studying stochastic programming, for sure.
    Fluctuation is represented by different power levels at different time instants.
    Supply is a decision variable (depending on the input data after optimization) so it is irrelevant.
    Since the renewable energy might fluctuates more frequently, we created the $\mathrm{F}=4$ option in our simulation, indicating that the RES updates 4 times faster (so does the energy storage system) than other devices. 
    \item \label{fitness} `compare' see \faq{compare}. The prime focus is not even on the speed gain, but on the \textit{fitness} (see \faq{naturalmotivation}).
    We think the biggest advantage is that our method fits our engineering application.
    \item Yes, scalability exists by design and has been included in the revised paper.
    \item \label{R1robust} This paper does not concern `robustness' in the sense of `robust optimization' (cf. \faq{algostability}).
    Nonetheless we do find in our experiments that our algorithm exhibits `numerical robustness'---the cutting
    planes can be added continually and the dual bound can make progress during the training effectively and there is
    no numerical hardship (e.g. there are no warning info observed from Gurobi's logging).
    So this is an observed behavior rather than a property to be demonstrated.
    Our (dual optimization) algorithm almost only entails adding violating cut, nothing else, which we deem `economic'.
    \item Yes. Apart from those modifications explicitly mentioned in this letter, there are some other refinements \blue{in the tracked-changes PDF}.
    \item The computational experiment section is an integral part of this paper, which goes beyond simple validation. The most noteworthy point is that we properly carried out an asynchronous programming simulation on the dual decomposition algorithm, which, based on our knowledge, is \textit{novel}. We've also make our test cases and the algorithm code publicly available so that our fellow researchers in the future can reuse if needed.
    In the scope of IEEE papers which are engineering-oriented, it is not rare to acknowledge the contributions of doing experiments since most of them entails much effort.
    \item Yes, we've mentioned this \blue{in the revised paper}. (cf. \faq{code})
\end{enumerate}

\section{R2-Question (answered in \sect{r2ans})}
Comments to the Author
\begin{enumerate}
    \item The core asynchronous cutting plane algorithm (Algorithm 3) lacks a transparent and rigorous explanation.
    \begin{enumerate}
        \item The paper does not clarify how task prioritization is handled when multiple blocks submit cuts simultaneously, nor does it define the conflict resolution mechanism for concurrent updates to the master LP's public status S. The interaction between block subproblems (Algorithm 1) and the coordinator;s master problem (Algorithm 2) remains vague—e.g., how the coordinator ensures consistency when processing cuts from asynchronous blocks.
        \item Key parameters like thread allocation strategy (TB) are only tied to hardware without justifying their impact on algorithm stability. The paper does not explain how to avoid race conditions when multiple blocks access/update shared data, nor does it provide benchmarks for asynchronous vs. synchronized execution (e.g., latency reduction, resource utilization).
        \item The experimental results only report final optimality gaps and runtime, without visualizing the asynchronous interaction process (e.g., cut submission frequency, master LP update intervals, block idle time). This makes it impossible to evaluate whether the asynchronous design truly avoids processor idleness as claimed.
    \end{enumerate}
    \item The proposed block decomposition and asynchronous algorithm lack sufficient theoretical guarantees, which undermines the academic rigor of the work:
    \begin{enumerate}
        \item No rigorous theoretical proof is provided for the convergence of the asynchronous cutting plane algorithm. Critical theoretical questions are unanswered: Does the algorithm converge to the global optimal solution of the original MILP? What is the convergence rate under different block configurations ($\rho$) and time resolutions (F)? No bounds on optimality gap reduction over iterations are provided.
        \item While the paper mentions `primal feasibility recovery,' it does not theoretically justify why the restricted primal MILP (34)--(37) can always recover a feasible solution, nor does it analyze the quality of the recovered solution relative to the dual bound. The relationship between the number of cuts and the tightness of the dual bound is only empirically observed (Fig. 6) without theoretical derivation.
        \item The paper claims the algorithm `is free of sophisticated stabilization techniques' but provides no proof of stability—e.g., how to prevent divergence caused by outdated dual variable $\beta$ in asynchronous updates, or how to handle cases where block subproblems return suboptimal solutions.
    \end{enumerate}
    \item The paper only compares with synchronized or centralized algorithms but ignores recent advances in asynchronous distributed optimization for MILPs (e.g., asynchronous Benders decomposition, distributed cutting plane methods). A fair comparison with methods like [19] is missing to highlight the novelty of the proposed asynchronous mechanism.
    \item The paper assumes perfect communication between the coordinator and blocks but does not consider real-world issues like communication delays, data loss, or partial block failures. No robustness analysis is provided for these scenarios, limiting the method's practical applicability.
\end{enumerate}

\section{R2} \label{r2ans}
Thanks for your careful reading and constructive comments. We hope the following reply clarifies your concern.
\begin{enumerate}
    \item `transparent': We think in this revision we've made that transparent. \label{remainsvague} `rigorous' see \faq{algovstheory}. The algorithm section is meant to be simple as it is natural, see \faq{naturalmotivation}. Also notice \faq{code}. \blue{We've added some notes at the end of Section IV}.
    \begin{enumerate}
        \item All three questions in this subitem appear to be concerns in single-threaded sequential programming. In our async experiments, these questions shouldn't be worried about by practitioners---they should be handled by the software automatically (in our case, julia)---as long as we write correct code.
        The algorithm is simple and natural as it really is (\faq{naturalmotivation}).
        \begin{enumerate}
            \item `Task prioritization': We'd like to ask: what did you mean precisely? In our Algorithm 3, only the spawning rule is specified by our practitioners. The rest is handled by julia automatically. (Partly answered also in R3-\ref{r3_future}.)
            \item `conflict': this won't happen since we've add locks properly. (This concerns practitioners writing correct code (of course). But we view it as an implementation detail---not `algorithmic')
            \item `interaction vague': As a programmer, we've specified the rule (or say, we've wrote concrete code). So the program would start running properly. It's a deterministic system. Nothing is vague.
            \par `ensure consistency': the wording is not very exact. We'd say \textit{validity} is ensured, which is already sufficient.
        \end{enumerate}
        For concreteness, you might want to read our code directly (in \faq{code}).
        \item `stability' see \faq{algostability}. It's \textit{not} tied to hardware---by typing a julia command we can alter `TB' programmatically.
        (We've \blue{modified our wording} in the revision. Thanks.)
        `race condition'---important, but we view it as a computer programming technic detail which is supposed not to reside in the main paper(\blue{we've added a note about `race condition' in the manuscript}).
        `benchmark' see \faq{compare}. All details are in \faq{code} (including how to add locks to avoid any potential race condition), but the (julia-specific/computer programming) implementation details are less than
        relevant to be presented in the main paper, we think.
        \item `iteration' see \faq{noiteration}. `visualize'---the motivation is good, but we think this mentality belongs to the single-threaded sequential programming field (just like `iteration') that is less related in the multithreaded asynchronous programming field.
        Only in small-scale tests one might want to `visualize', but that's not the case where multithreaded programming is effectively needed.
        Moreover, to visualize one has to add logging code which would disturb the original process somehow.
        We believe that the mentality of sequential programming doesn't carry over well to the async world, and we really only need to focus on the validity of the theories (\faq{algovstheory}).
        `processor idleness'---we believe this term (that we had used) is less relevant\footnote{We think that in real-world the sole aim is to yield desired results effecitve-and-efficiently, given a certain hardware.} so \blue{we've deleted it}, Thanks. 
        (The intended mentality is simply and only \faq{naturalmotivation}.)
    \end{enumerate}
    \item `rigor' see \faq{algovstheory}.
    \begin{enumerate}
        \item `converge' see \faq{noconverge}. `global' see \faq{ourisglobal}.
        `rate' see \faq{algospeed}. `iteration' see \faq{noiteration}.
        The mentality of sequential programming doesn't carry over well to the async world.
        \item We've \blue{modified the wording} in the revision. We manually \blue{introduce a warm-up phase} so feasibility exist at the beginning.
        `nor does it analyze'---we think this assertion is not true---where did you get this conclusion?
        `relationship': The more violating cuts we add, the tighter the dual bound is. There is no additional meaningful relation---mathematical analysis doesn't reside here, we believe.
        \item `stability' see \faq{algostability}.
        `divergence': this never happened and will never happen (see Theorem 1, 3, 4 in our revised manuscript, or you might to run our code).
        `outdated'/`suboptimal': they are \textit{defined behavior} and are acceptable.
        All your concerns here are handled automatically, see \faq{imperfectcommunication}.
        We are in the world of global optimization \faq{ourisglobal}, readers only need to focus on the validity.
        A `suboptimal solution' still admits of valid primal and dual bounds, so it is not an outlier.
    \end{enumerate}
    \item \label{like19} Thanks. We believe [19] was based solely on sequential programming that run code on a single thread.
    For the rest, see \faq{compare}.
    This paper addresses dual decomposition only.
    Benders decomposition is another topic albeit similar---not all work should be done in a single paper, we think.
    You may also be interested in reading our reply in R5-\ref{r5_1}.
    \item \label{r2_4} see \faq{imperfectcommunication}. 
    The \textit{sole} sense of the word `robust' pertaining to this paper occurs in \faq{algostability}.
\end{enumerate}

\section{R3-Question (answered in \sect{r3ans})}
This paper provides a new decentralized solution for the operation of distributed energy resources. Please refer to the following questions.
\begin{enumerate}
    \item In the computational experiments, the authors adopt the dual computation time $t^{dual}$ as the time limit $t^{lim}$ for the proposed algorithm. While this choice appears reasonable from a practical standpoint, a more detailed explanation of its rationale would be helpful. In particular, it would be interesting to further clarify why $t^{dual}$ is considered an appropriate reference for evaluating the convergence behavior and computational efficiency of the proposed asynchronous cutting-plane framework.
    \item The asynchronous implementation is a key contribution of this work and is shown to significantly improve the overall computational efficiency. However, due to the asynchronous nature, the master task may be re-optimized before all block-level tasks have completed their current subproblem solves. Although the numerical results demonstrate clear performance gains, it may still be valuable to include additional theoretical or qualitative discussion on how such partial information updates affect convergence efficiency, for example in terms of cut utilization or dual bound progression.
    \item The computational experiments primarily focus on a single large-scale test system, which effectively demonstrates the scalability of the proposed method. As a possible extension, the authors may consider adding a smaller-scale test case to provide a comparative perspective, which could help further illustrate how problem size impacts convergence speed and computational efficiency under the proposed asynchronous framework.
    \item In the asynchronous implementation, different block-level tasks may exhibit significantly different solution times due to heterogeneity in block sizes and local problem complexity. This raises an interesting question regarding task scheduling: would prioritizing slower or more computationally intensive tasks potentially improve the balance of cut generation across blocks and further enhance convergence behavior? A brief discussion on this aspect, even as future work, could provide additional insight into the practical deployment of the proposed algorithm.
\end{enumerate}

\section{R3} \label{r3ans}
Thanks for your careful reading and constructive comments. We hope the following reply clarifies your concern.
\begin{enumerate}
    \item The choice ($t^{dual}$) is natural, see \faq{goaldualtrain}. see also \faq{noconverge}\faq{noiteration}.
    Since iteration count is irrelevant, $t^{dual}$ is the only option. However, it can depend on hardware, that's
    why we have Fig. 6.
    \item `partial information': this term is not very accurate. We only have `valid information', which
    is from violating cuts. We've \blue{rewritten our theory section} (cf. \faq{algovstheory}) that you may want to have a look at.
    \item `convergence speed' see \faq{algospeed}. Thanks for the suggestion. We don't think
    problem size is a factor that we should be interested in. First, it has no direct relation to the
    theory that underpinning our algorithm. Second, the application assumes that each block (i.e. each subproblem)
    has a computing device. So we are not in the single-thread sequential programming world.
    We'd encourage interested readers to think about the theory and then conduct experiments in large scales boldly.
    Since there is no problem with the theory, the outcome \textit{should} be satisfactory.
    \item \label{r3_future} Thanks for the thoughts. It's partly answered in R2-\ref{remainsvague}.
    The same question I wonder is `What did you mean precisely by task prioritizing?'.
    As a programmer, we only need to care about the rule of task spawning.
    In julia, theoretically speaking, we can create a task and then schedule it later on.
    But that's not common practice. Moreover, even if a task is scheduled first, it does not necessarily mean it be run with higher priority.
    And this probably make some sense only when the cpu resource is scarce, which is not the case in the application in this paper.
    \blue{We've added some comments at the end of Section IV.}
    Frankly speaking, from the standpoint of a (julia) programmer, I have no idea (at the current stage) where this idea can lead me to. Might be seen as future work.
\end{enumerate}

\section{R4-Question (answered in \sect{r4ans})}
Based on multi-threaded asynchronous programming, this paper proposes a decentralized coordination framework for the operation of distributed energy resources in residential communities to produce high-quality optimization decisions. Overall, the paper is clear and well-written, but there are still some areas that require further clarification. Please carefully consider the following comments:
\begin{enumerate}
    \item In the example analysis, the optimization gap benchmarks of different scale cases (443 households and 28336 households) are inconsistent (0.1\% and 0.01\%), which affects the clarity of comparison, and it is suggested to unify the error measurement standard. At the same time, the improvement of the solution speed lacks quantitative data, and the supplement of the calculation time comparison will make the argument more complete.
    \item The decision support software and smart devices mentioned in the introduction are more general. Please specify what they refer to in the context of this study and what key data or functional support they can provide for multi-energy coordinated optimization.
    \item In the introduction, there is too little literature on the work related to block decomposition, and it is suggested to supplement the overview of representative methods in this field and their application in energy coordination.
    \item In the modeling of deferred load, the author defines paired blocks as computing units, assuming that a family only participates in one borrowing relationship. This is inconsistent with the sharing model that may be more economical in reality (a family generates multiple borrowing relationships). Please discuss this limitation or consider changing the model.
    \item The “valid artificial finite dual bound” added in the initialization of the algorithm lacks a clear definition. Please explain its specific mathematical form and selection principle.
    \item The range of various parameters (such as COP, CND) is set in the example. Please briefly explain its selection basis to enhance the rationality of parameter setting.
\end{enumerate}

\section{R4} \label{r4ans}
Thanks for your careful reading and constructive comments. We hope the following reply clarifies your concern.
\begin{enumerate}
    \item First, there is MILP hardness (cf. \faq{ourisglobal}) so there is generally no guarantee to reach, say, 0.1\% (We
        also had a statement beginning with ``Note that'' at R5-\ref{r5_6} that might be slightly relevant).
        Second, those two results are not intended to be compared---the one is 1-to-1 simulation while the other is not.
       `solution speed' see \faq{algospeed}.
       One thing is that we've already have a staircase curve (Fig. 3).
       Another thing is that it's not all about speed gain, but our method fits the real-world application (cf. \faq{naturalmotivation}).
       `compare' see \faq{compare}.
    \item Thanks. We've \blue{modified the wording and explained} in the revision. The software is MILP solvers. Smart meters can communicate etc.
    \item \label{blockdecompocite} Thanks. We've \blue{added a reference} \cite{liu2024} to our paper, which also uses block decomposition, mixed-integer subproblems and studies local energy system in neighborhoods.
    I think the current sorts of methods are already many---ADMM, Benders decomposition, dual decomposition, Dantzig-Wolfe decomposition etc.
    The common point is probably making use of decomposibility.
    And we believe that \cite{dw2019}\cite{chenrui2024} already serve as good references.
    \item \label{multihouseblock} From the standpoint of modeling, one can definitely model multiple borrowing relationships inside a block
    subproblem, e.g. using a more complex MILP model. And it doesn't fall outside the framework designed in this
    paper---the methodology still applies. Since the decision space is enlarged, more economical solutions might
    exist, albeit at the expense that the MILP for the corresponding block (wherein multiple households are
    coupled) might become harder to solve.
    \par
    One soft requirement of the application for which a decomposition method becomes more advantageous
    than a centralized monolithic solve is that the subproblem MIPs are easier to solve.
    The main purpose of this paper lean heavier on the master-subproblem (nonlocal-level) interaction.
    So, incorporating more complicated models locally at intra-block level might be done in future researches.
    \par
    So this is not a limitation. We've \blue{added a footnote in Section II} to clarify this.
    \item This concerns \blue{warm-up} that happens in virtually all decomposition algorithms (so
    we incline to the view that practitioners in this field should \textit{had} known how
    to perform this rather than say, learning it from our paper).
    That quote you mentioned was meant to be general since (i) the method to build a finite dual bound is nonunique,
    (ii) that's inside the algorithm section while we gave more details in the case study section.
    The finiteness at the dual side is due to the feasibility at the primal side.
    We've \blue{made it more formal} (there are two footnotes about this, you can search (ctrl+f) them by `prior knowledge', `collected').
    And there are \blue{other related places} you may notice that we've revised to make this clearer.
    We believe there is no such a mathematical form---it's more like a mild-level expertise of practitioners.
    You are welcome to read our code (and search `warm') if you have strong interests. See \faq{code}.
    \item The parameters concern the test cases randomly generated based on general physics knowledge, which is common in papers studying optimization.
    For example, the Eq. (11) is a linearized state equation:
    \[
        \mathrm{CND}(\mathrm{O}_t - o_t) + \mathrm{Q}^\mathrm{I}_t - q_t - \mathrm{COP} p^\mathrm{AC}_t = \mathrm{INR}(o_{t+1}-o_t)
    \],
    which admits of a numeric realization
    \[
        2*(41-29) + 0 - 0 - 3.5*3 = 7.25 * (31-29)
    \], in which all quantities are rational (41 Celsius is not rare in Xi'an, hot summer).
    The main goal is to ascertain the performance of our algorithm across a wide range of numeric inputs so it may have wider applicability. So device parameters lie in intervals.
    From the standpoint of test results, we did observe that with the current input parameter setting,
    we have chances to both generate simple and hard MILP subproblems (emulating the heterogeneity
    in real neighborhoods), which reflects the rationality of our set of choices.
    On the other hand, instead of focusing on designing the range of a single type of device,
    more effort is needed to see if the \textit{relative} scales are reasonable and ensure the consistency
    among all devices (e.g. Eq. (63)).
    We believe that our algorithm can maintain its performance under any other (rational) input data, as long as they exist.
\end{enumerate}

\section{R5-Question (answered in \sect{r5ans})}
This work proposes a decentralized scheme to exploit demand-side flexibility, in which multiple energy sources and social interactions among residents are taken into account. Overall, this is an interesting study. The reviewer has the following comments:
\begin{enumerate}
    \item The literature survey is not sufficiently comprehensive. Asynchronous algorithms have already been extensively applied in related areas such as load scheduling and coordinated energy management; however, these studies are not discussed in the manuscript. The authors are strongly encouraged to conduct a more thorough review of the relevant literature and explicitly position their work with respect to existing asynchronous approaches, such as \cite{wang2023}\cite{patari2023}\cite{wu2025}.
    \item The manuscript assumes that renewable generation is curtailable. However, if no curtailment penalty is included in the objective function, the optimal solution may theoretically drive renewable generation to zero, which is generally unacceptable from the users’ perspective. The authors should clarify this modeling choice and consider incorporating an appropriate curtailment penalty or constraint.
    \item How are social contacts defined or classified in the model? Is there any theoretical or empirical basis for this classification, or are social links generated randomly? Moreover, the authors should explain how different social contact structures affect charging load behaviors.
    \item Please provide a rigorous theoretical convergence proof for the algorithm proposed in Section III, along with a gap or optimality analysis to characterize its convergence properties.
    \item Does the asynchronous framework explicitly account for practical factors such as communication delays, packet loss, or heterogeneous update rates? Further clarification is needed regarding the realism of the asynchronous assumptions.
    \item In Figs. 4 and 5, the solution time for the power rating problem is significantly longer than that for the energy cost problem. Please explain the underlying reasons for this discrepancy and discuss the different computational challenges associated with these two problem formulations.
    \item In Fig. 7, the differences between the two compared cases appear relatively small. Please elaborate on the significance of these differences. In addition, the authors should explain why social interactions help reduce load during high-price periods.
\end{enumerate}

\section{R5} \label{r5ans}
Thanks for your careful reading and constructive comments. We hope the following reply clarifies your concern.
\begin{enumerate}
    \item \label{r5_1} Thanks for the recommendation.
    We'd like to point out that our paper is not a repetition of the existing researches.
    A trivially observable fact is \faq{asynccode}.
    The second fact is that we are doing global optimization with dual bound guarantee (cf. \faq{localglobal}) and our theory
    is based on constraint generation (cf. \faq{notadmm}).
    Please see our detailed feedback in \faq{admmpapers}.
    \blue{We had added} \cite{wang2023}\cite{wu2025} to our introduction section.
    \item Thanks for the advice. We've revised this part both in the manuscript and in the code (\faq{code})---\blue{a curtailment variable $\varpi$ and its associated penalty term}.
    Actually, we only assumed our model is an MILP with block structures---\textit{All} decision variable of each household can be priced onto the objective. It doesn't change the fundamental sense of the optimization. So we are actually proposing a framework rather than a particular instance of engineering application, resembling \cite{dw2019}.
    \par
    Our original formulation is a special case where the cost coefficient associated with $\varpi$ is zero. Theoretically speaking, the renewable generation should be utilized if it exists when needed because it can be used at no cost---otherwise that same amount of energy should be imported from the circuit breaker which has positive costs (i.e. an inferior solution that is unlikely to show up).
    We've \blue{added a footnote in the manuscript} to clarify this.
    \item \label{r5_3} In our setting, the coordinator interacts with $\mathrm{J}$ blocks.
    There are two types of blocks: block comprising exactly one household, or more.
    For the former case, no social contact is involved---a household is an individual operation unit.
    For the latter case where the block contains multiple households, social contacts (i.e. coupling between households) can be modeled.
    In our paper, both types of blocks are considered, with a percentage $\rho$ (in case studies),
    Theoretically, social contacts in more complex form can be modeled, but that's merely a specific choice of \textit{local} model, which doesn't affect the overall (MILP with block structure) setting.
    (cf. R4-\ref{multihouseblock}.) (\blue{A footnote was added in the manuscript about this point.})
    Therefore we only implemented the social contact in the form of EV lending between two households.
    \par
    The social links, specifically the EV lending possibility, exist in each block with a pair of households.
    And we made sure that the flow direction of lending power goes from household 1 (with RES) to household 2 (without RES), which is quite intuitive.
    So it can be perceived as empirical-based (the algorithm theories of this paper did't pertain too much here).
    \par
    The EV charging dynamics are modeled in MILP form.
    Actually, the original (no EV lending) model is a special case derived from the current (allow EV lending) model
    by adding the restriction $b^\mathrm{Lent} \equiv 1$.
    So from the mathematical sense we are doing a proper extension.
    In physical terms, the load of household 2 might be alleviated since EV2 can also be charged
    in household 1.
    In optimization terms, at certain $t$'s, the constraint about the EV2's circuit breaker's limit
    might be less likely to be binding (than the original no EV lending setting).
    \par
    To sum up, (i) it's a standard MILP model so it is self-explanatory just like the other devices,
    (ii) this happens locally inside a block while this paper lean more weight on coordinator-customer interaction.
    (Related to R5-\ref{r5_7})
    \item \label{r5_4} From our perspective: we first have theory, then the algorithm---not the reverse direction. \blue{Section III (=theories) has been rewritten and Section IV (=algorithm of the dual optimization) has been revised.} See also \faq{noconverge} and \faq{algovstheory}
    \item answered in R2-\ref{r2_4}.
    \item \label{r5_6} We think there is nothing too mysterious about this behavior and it is caused probably by the nature of the problem
    rather than the specific algorithm being used.
    \par
    In our experiment, the min-cost problem is built at a higher level.
    The neighborhood circuit breaker limit---the quota $\mathbf{b}$ in `$\mathbf{A}\mathbf{x} \ge \mathbf{b}$'
    is not well-understood a priori---how large should this input parameter be?
    It cannot be too small---otherwise the overall problem is infeasible.
    It cannot be too large, otherwise we are studying a degenerate problem where the coupling constraint is always inactive (nonbinding).
    \par
    To tackle the above issue, the strategy we adopted was that we decide
    a proper value of $\mathbf{b}$ (the input to the min-cost problem)
    \textit{after} solving the min-rating problem (where we would have a concrete lower-bound limit).
    And the initial feasible solution (one for each block) to meet the assumption (in footnote 7, which relates to warm-up)
    was also collected during solving the min-rating problem.
    \blue{We've clarified these two facts in the footnotes in the revision.}
    \par
    We think the above strategy is a general skill rather than something closely related to the main idea of the paper.
    There is no theories suggesting one type of problem is harder than the other.
    (Note that the hardness of an MILP is not defined by the time entailed to let the gap drop to 0.01\%.
    You may use 1 second to attain 0.01\% and use 1 year to attain 0\%.)
    There is not many meaningful remarks we can make regarding the current behavior.
    \item \label{r5_7} There is a red and a green staircase curve that might seem `only different at certain time periods'.
    But focusing on the \textit{load shifting} capability, the `social activity' did take effect.
    A small difference in physical quantity doesn't imply a small difference in the resulting cost.
    Moreover, this flexibility is procured at no additional capital cost.
    \par
    Regarding your final question, `reducing load in high-price periods' is the defined behavior of all
    demand response program (or generally speaking, cost-minimization problems), which is not restricted to
    our `social activity' module.
    By enabling the social interaction, the EV-charging flexibility is enhanced (as mentioned in R5-\ref{r5_3}).
    And so the overall feasible set (accommodating all devices introduced in Section II) is enlarged. 
    That means there are \textit{more alternative policies} to arrange the energy consumption in a 24-hour planning horizon.
    Since the total load is not decreased or increased but transfered between households, the final
    observation reads as the load is shifted along the time axis. So it is not an unexpected result.
\end{enumerate}

\section{FAQ} \label{faqsect}
\begin{enumerate}
    \item \label{notadmm} \textbf{Our paper is not ADMM-based.} (cf. \faq{admmpapers} for some ADMM-based papers)
    There is a convergence-related claim in ADMM: Assume certain conditions (convexity, saddle-point, etc.),
    the sequence $\{x^k, \lambda^k\}$ generated by the iteration \textit{converges to} some optimal
    primal and dual optimal solution pair ($x^\ast, \lambda^\ast$).
    From this we know that \begin{enumerate}
        \item The ADMM cannot provide a valid upper bound \textit{along with} a valid dual bound \textit{in each
        iteration of its training}. By comparison, the cutting plane method\footnote{that our core algorithm is based on} \textit{can}.
        (In our async setting, during the dual optimization phase, one can\footnote{Although we won't try to interrupt arbitrarily and do that post-processing because it would be very tricky (and not worth) to write code.} interrupt the training at any instant
        and do a post-processing to get a valid gap calculated from bounds.)
        \item The \textit{convergence} concept pertains to the trajectory of the \textit{decision vector}. (By comparison,
        in the cutting plane method, we \textit{don't need to} care the trajectory of the decision vector $\mathbf{x}$ along
        the training. We only need to\footnote{If being more precise, in our async dual optimization, we only need to monitor the progress of the dual bound.} monitor the gap shrinking progress (see Theorem 3--6, and also
        \faq{localglobal}).
    \end{enumerate}
    \item \label{noconverge} \textbf{Converges to what?} (Please cf. \faq{notadmm}) Since our method is gap-based, it judges
    solution quality using absolute (i.e. independent, or `itself-make-sense') measures---valid
    upper\&lower bound to the optimal objective value.
    Therefore, it doesn't make much sense to discuss our method with the word `convergence' (\blue{We've modified our wording in the revised manuscript}) (cf. \faq{localglobal}).
    Instead, we only need to keep in mind the validity results (Theorem 3--6).
    \item \label{noiteration} \textbf{What's an iteration?} (cf. \faq{noconverge})
    In asynchronous programming context, does the concept of `an iteration' exist?
    Yes, it does. For example,
    the master problem has updated its coordination signal $\boldsymbol{\beta}$,
    which can be deemed an iteration.
    However, it is just not meaningful to talk about algorithm speed with this
    concept of `iteration'.
    \par
    Indeed, the master problem may recruit one cut and conduct a re-optimization (to generate
    $\boldsymbol{\beta}$), or it can recruit a bunch of cuts and conduct a
    re-optimization.
    Both situations are valid in practice.
    Therefore, the notion `iteration' literally can not be used in talking about
    algorithm speed.
    \item \textbf{What's our algorithm's speed?} \label{algospeed} (cf. \faq{noiteration}.) Just like
    the notion of `convergence', we don't think there is a clear concept of
    `convergence speed' in our asynchronous multithreaded programming setting.
    We believe that the `termination gap + training time' should be used \textit{in practice},
    which is common in the research field of mixed-integer programming. 
    \item \textbf{What's global/local optimization?} \label{localglobal} Typically the term `local optimization'
    occurs in NLP (nonlinear programming) context, which doesn't involve discrete decisions.
    Ipopt can be deemed a standard local optimization solver---it cannot provide a
    valid dual bound so we would have no absolute measure (cf. \faq{noconverge}) of solution quality.
    The purpose of local optimization is to attain a local optimum, e.g. using the
    classic Newton's method. Therefore, in local optimization context it makes sense to
    talk with concept `convergence' and `convergence rate' (cf. \faq{noconverge}).
    And in local optimization context it does make sense to compare two local optimization algorithms,
    (relative measure matters in the absence of absolute measure).
    For example, Ipopt2 returns a smaller primal bound than Ipopt1, then Ipopt2 wins.
    \par
    Our application is MILP-based, which basically does NOT aim at attaining
    a particular optimum---since MILPs are NP-hard.
    What we can do is to retrieve a primal feasible solution (thereby
    the primal bound) as well as a valid dual bound, from which we can judge our solution quality
    using absolute measures (cf. \faq{noconverge})(Also cf. \faq{ourisglobal}).
    \item \textbf{Our paper is a global optimization on a MILP.} \label{ourisglobal}
    (see \faq{localglobal} first)
    Gurobi, as a MILP solver, provides a primal bound (\texttt{ObjVal}) as
    well as a dual bound (\texttt{ObjBound}).
    You can think of our methodology as a higher-level solver that is based on Gurobi,
    which means that we can also provide valid primal and dual bounds.
    Since Gurobi cannot guarantee solving an MILP to zero gap in a finite time,
    neither can our method. 
    But the real meaningful thing is just \textit{not to} attain global optimality,
    but is instead to see if small gaps can be reached within a certain training period. (cf. \faq{practicallyoptimal})
    \item \textbf{Goal of solution quality} \label{practicallyoptimal} (cf. \faq{ourisglobal})
    For a practical application like the neighborhood coordination in this paper,
    a $0.1\%$ termination relative gap is already deemed \textit{practically optimal}.
    It doesn't make much real-life sense to further pursue the global optimum (0~gap) because there are
    modeling errors where approximation was used, which is inevitable for every research paper.
    \item \textbf{What is the goal of dual training?} \label{goaldualtrain}
    The eventual aim is to get close to $z^\mathrm{IP}$ (surely). However, that concerns the
    inherent hardness of MILP (cf. \faq{localglobal}\faq{ourisglobal}).
    So it's a consensus of researchers to change their aim to $z^\mathrm{L}$---the Lagrangian bound.
    That's exactly what the dual training phase (the main algorithm in our paper) is targeting
    (this dual optimization phase admits distributed optimization).
    You may wonder: then how to address the gap between $z^\mathrm{L}$ and $z^\mathrm{IP}$?
    The answer is: that part might entail heavy branch-and-bound and is not multithreading-friendly
    so we just cannot afford to spend much time on it.
    \item \textbf{Stability?} \label{algostability} (cf. \faq{noconverge})
    There is many material teaching people how to `stabilize' their cutting plane algorithm.
    We are not aware of a formal definition of `algorithm stability' (especially
    in an async setting, please also note that we have no `iteration' cf. \faq{noiteration}).
    To us, it sounds like a subproperty of algorithm speed (cf. \faq{algospeed}).
    We surmise that the so-called `stability' issue only occurs in sequential programming
    based algorithms (Personally I did see a bunch of work on this).
    So far we haven't observe a `stability' issue occurs in our experiments.
    As such, we have no plan to continue along this track.
    \par
    By the way, we'd like to point out that our algorithm exhibits numerical stability
    in our experiments, or say `numerical robustness' which should be of
    identical meanings. This, however, is a different concept (mentioned in R1-\ref{R1robust}).
    \blue{We've modified our wording to `numerical stability'.}
    \item \textbf{Our motivation is simple and natural.} \label{naturalmotivation}
    We study coordination of residential customers in this paper.
    There are $\mathrm{J}$ household blocks, each of which is assumed to having
    an individual computing device (solving MILP subproblems).
    The most \textit{natural, basic and naive} idea is---the coordinator has no need to
    wait for any particular block, if it is ready to update
    the coordination signal $\boldsymbol{\beta}$.
    (Was there anything I missed? I think no.)
    You can even think of it as if we were motivated by the non-blocking programming
    concept in computer programming.
    Due to such simple motivation we had implemented the cutting plane algorithm in asynchronous
    programming fashion.
    Also cf. \faq{imperfectcommunication} and \faq{asynccode}.
    \item \textbf{Where should the rigor lie?} \label{algovstheory}
    We'd like to emphasize that our Section IV (presenting the algorithms) is almost
    a natural consequence---there is no sophisticated stuff in Section IV (cf. \faq{naturalmotivation}).
    (Although it can be somewhat nontrivial to properly implement the executable computer program,
    this sort of content is not supposed to reside in an IEEE paper).
    The rigorous stuff are in Section III (\blue{that we've rewritten thoroughly}).
    To understand our core idea, you can either read Section III, or you can read our code in \faq{code}.
    \item \textbf{All implementation details are in our code.} \label{code}
    There is nothing opaque---you might want to read \url{https://github.com/zchenytt/CEMS/tree/main/src/async}.
    \blue{(these are not changes in the manuscript but)} We've spent some time these days to organize the layout of our code so it is now neat to read.
    Note that to run the code you don't need a 256-thread server.
    For example, my laptop has Intel Core i5-1135G7 (4 physical cores, 8 threads) and 16GB memory.
    So you may create a $\mathrm{J}=5$ instance that meets the 1-to-1 condition.
    Or without the 1-to-1 restriction you can increase $\mathrm{J}$ and run tests as long as the memory allows.
    It works really well on my laptop.
    \item \textbf{Our algorithm can intrinsically deal with imperfect communication.}
    \label{imperfectcommunication} \blue{(We've mentioned this at the end of Section IV)}
    Our cutting plane theory (Theorem 3--6) is fundamentally compatible with
    the asynchronous programming functionality in julia. 
    In other words, all the validity assertions carries over from the sequential programming
    field to asynchronous programming field that we are now working with.
    In our experiments, different blocks are \textit{already} having heterogeneous optimization times (as their respective MILP subproblems are having different complexities).
    From the viewpoint of the coordinator, the optimization time of a block is not distinguishable from its communication-delayed time---they add up to form a `feedback time' of the block.
    As mentioned in \faq{naturalmotivation}, there is no reason for the coordinator to wait any particular block just because a certain feedback is not available.
    Therefore, the system excluding those abnormal parts would still work as usual (Actually, our experiment results in Section V are derived under heterogeneous feedback times).
    Inherently speaking, nothing is complicated:\begin{enumerate}
        \item block failure is nothing but a prolonged packet loss 
        \item data loss $\equiv$ packet loss
        \item packet loss is nothing but a prolonged communication delay
        \item heterogeneous update rates is actually \textit{the normal state} in our setting
    \end{enumerate}
    To conclude, our method \textit{is designed in such a way} to be able to handle imperfect communication conditions \textit{as usual}.
    \item \textbf{We made proper use of Asynchronous Programming in our simulation.} \label{asynccode}
    A lot of other work describe their algorithm as `asynchronous',
    but we find that \textit{only} our paper made proper use of Asynchronous Programming
    techniques (we used julia, mentioned in \faq{code}).
    \item \textbf{Compare to what?} \label{compare}
    Note that we can assess our solution quality using absolute measures (see \faq{localglobal}).
    So we essentially obviate the need of comparing with other methods.
    \par What's more, \begin{enumerate}
        \item We've conducted a comparison with the centralized method in our paper (that staircase curve, which used 1-thread sequential programming).
        \item We don't think it is meaningful to compare with a parallel-programming with sync-point
        existing in each master's re-optimization.
        As mentioned in \faq{naturalmotivation}, adding a sync-point for all blocks is counter-natural (or say, just won't be adopted in practice).
        The proper mindset of scientific study is---we first accept a theory as plausible, then we
        do experiments.
        \item We are not aware of a `state-of-the-art distributed asynchronous algorithm' that deserves
        comparison (Also cf. \faq{notadmm} and cf. \faq{asynccode}).
    \end{enumerate}
    We've mentioned in \faq{naturalmotivation} that our method is already a standard one (at least we think).
    In fact, we believe that our method can serve as a baseline method for any future work to
    compare with. Note that we've made our code available \faq{code}.
    \item \textbf{The 3 papers raised by Reviewer.} \label{admmpapers}
    We give our feedback on the papers mentioned in R5-\ref{r5_1}.
    \begin{enumerate}
        \item \cite{wang2023} is indeed highly relevant, in which the operation of DSO and VPPs is coordinated. Based on our understanding, their async setting was mostly motivated by delayed or lost data during the communication between the DSO and VPPs.
        While in our work, the async setting is deemed the righteous solution that should be adopted in real-world settings (cf. \faq{naturalmotivation}).
        Their model is continuous but highly nonlinear whereas our work involve discrete decisions.
        Compared to our work, their solution method involves some hyperparameters that entails tuning.
        While conceptually sound, their method is not lightweight, e.g. due to the `hybrid' design.
        So there is some barrier if other fellow researchers want to re-implement. (By comparison, our method is natural and easy to reproduce.)
        The biggest question in our mind is that why they didn't opt to use Benders Decomposition,
        which decompose the DSO and VPPs from the primal side.
        You see, in their model, the number of copy constraints and dual variables grow linearly
        with the number of VPPs, which goes up in large-scale settings.
        This wouldn't happen if a Benders' framework were adopted.
        According to their two case studies---IEEE 33- and 123-bus systems,
        their distributed algorithm took $>1.25$ times longer (from TABLE II) than the centralized algorithm.
        In our work, the centralized algorithm is slower for large cases.
        They mentioned `mixed integer programming' in their CONCLUSION part---what
        we are doing now.
        So, yes, this is a relevant citation.
            \item  \cite{patari2023}  aims at generating
        optimal active and reactive power setpoints for the voltage control agents.
        Based on our understanding, the concept `asynchronous' associates to the communication pattern,
        which is closer to being an environmental setting.
        While in our work, `asynchronous' is a manner in which cutting planes are added to the master problem---an algorithm design choice to fit the studied neighborhood coordination problem.
        The optimization problem in \cite{patari2023} didn't involve multi-period due to their online real-time
        problem setting.
        A 3-phase unbalanced network was considered in \cite{patari2023}, where the voltage control agents share
        variables only with their neighboring buses.
        Both the communication style and the physical problem are not close to the setting in our work.
        Therefore, we don't think their work is strongly correlated to ours in terms of research scope.
            \item \cite{wu2025} focused on real time energy sharing between prosumers.
        From the standpoint of the subject matter, this issue is related to our paper.
        Compared to our method, there are still several different points.
        At first, their method is ADMM-based while ours are based on dual decomposition. 
        The master problem in our setting has an explicit cutting plane model that is monotonically enriched along the training (Theorem 3 in our revised manuscript).
        Whereas according to our knowledge about the ADMM framework, they only conduct point iteration.
        Therefore, the convergence issue is a main focus in their setting.
        This is not the case considering our dual decomposition setting (cf. \faq{noconverge}).
        The core thing we care about is the validity of upper and lower bounds (see the Section III in our revised paper).
        Since the main algorithmic idea in our setting is constraint generation,
        the finite termination is fulfilled by the finiteness of the number the vertices
        of the polyhedron, which holds by the finiteness of number of physical constraints.
        Given the Fig.~1. of \cite{wu2025}, I notice that the update of the coordinator relies on feedback
        of every prosumers?
        This is not the case at our setting, in which the coordinator can generate a new coordination signal (i.e. $\boldsymbol{\beta}$) even if only one block contributed a violating cut.
        Therefore, we won't need to predict what a particular subproblem reacts, as long as the validity of the
        existing cuts holds.
        In their algorithm section (IV. therein), a sync-point was introduced that remedies unacceptable discrepancies.
        While in our setting, the coordination procedure is fully asynchronous throughout and the convergence
        trend is unaffected.
        About the scalability, they considered at most 100 prosumers.
        While in our tests, neighborhoods with tens of thousands of households are investigated.
    \end{enumerate}
    % \item \textbf{Feasibility can be established in advance.} \label{feasibility}
    % An optimization problem \textit{is nothing but} a feasibility system plus an objective function (
    % and the sense being `Min' or `Max').
    % In engineering context it make sense to assume that we are \textit{already} aware of at least one
    % feasible solution---though we may not be able to enumerate all possible solutions and
    % be clear about which particular solution leads to the minimum cost a priori.
    % On how to procure a feasible solution, see post \#5--6 in
    % \url{https://discourse.julialang.org/t/initial-guess-is-not-an-interior-point-in-optimization-methods/133727/5}.
    % \item \textbf{How to warm up?} \label{warm-up}
    % All decomposition algorithm needs to be warm up properly, including Benders decomposition,
    % dual decomposition, no matter you are doing stochastic programming or robust optimization or
    % distributionally robust optimization.
    % Since it is asked by the reviewers, we answer it here.
    % But we are not planning to write this in detail in our main paper---this really is basic
    % knowledge, and the issue `how to warm up' occurs in every research paper
    % that uses decomposition, and the warm-up strategy is not unique (it is customizable).
    % \par
    % According to the strong duality of linear programming, a finite dual bound can be procured
    % if you are aware of a primal feasible solution.    
    % The basic idea is to prepare feasible solutions on the primal side.
\end{enumerate}


\begin{thebibliography}{1}
\bibliographystyle{IEEEtran}

\bibitem{wang2023}
Q. Wang et al., "Asynchronous Decomposition Method for the Coordinated Operation of Virtual Power Plants," in IEEE Transactions on Power Systems, vol. 38, no. 1, pp. 767-782, Jan. 2023.
\bibitem{patari2023}
N. Patari, A. K. Srivastava and N. Li, "Distributed Optimal Voltage Control Considering Latency and Asynchronous Communication for Three Phase Unbalanced Distribution Systems," in IEEE Transactions on Power Systems, vol. 38, no. 2, pp. 1033-1043, March 2023
\bibitem{wu2025}
Y. Wu, T. Yu, Z. Pan and Z. Wang, "Best Response Learning Assisted Asynchronous ADMM for Real-Time Energy Sharing Under Communication Delay," in IEEE Transactions on Smart Grid, vol. 16, no. 4, pp. 3239-3255, July 2025.
\bibitem{dw2019}
M. F. Anjos, A. Lodi and M. Tanneau, ``A Decentralized Framework for the Optimal Coordination of Distributed Energy Resources,'' in \textit{IEEE Transactions on Power Systems}, vol. 34, no. 1, pp. 349-359, Jan. 2019.
\bibitem{liu2024}
B. Liu, C. Bissuel, F. Courtot, C. Gicquel and D. Quadri, ``A generalized Benders decomposition approach for the optimal design of a local multi-energy system,'' \textit{European Journal of Operational Research}, vol. 318, no. 1, pp. 43-54, 2024.
\bibitem{chenrui2024}
R. Chen, O. Günlük and A. Lodi, ``Recovering Dantzig–Wolfe Bounds by Cutting Planes,'' \textit{Operations Research}, vol. 73, no. 2, pp. 1128-1142, 2024.
    
\end{thebibliography}

\end{document}
