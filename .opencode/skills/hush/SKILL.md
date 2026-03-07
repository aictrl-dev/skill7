# Skill: hush

Automated code review system powered by GLM-5. This skill enables the agent to systematically analyze pull requests and provide high-quality, actionable feedback directly as GitHub comments.

## Workflow

1.  **Context Loading:** Identify the current PR and its changes (diffs).
2.  **Analysis:** Use GLM-5 to perform a multi-turn analysis of the changes, focusing on:
    -   **Logical Correctness:** Identifying potential bugs or regressions.
    -   **Security:** Spotting vulnerabilities or sensitive data leaks.
    -   **Performance:** Suggesting optimizations for hot paths.
    -   **Style & Standards:** Ensuring alignment with the project's coding standards.
3.  **Comment Generation:** Formulate concise, polite, and constructive comments for specific lines or files.
4.  **Integration:** Post the comments to the GitHub PR using the `github-comment` tool.

## Guidelines for GLM-5

-   Prioritize high-impact issues over nitpicks.
-   Provide code examples for suggested changes whenever possible.
-   Maintain a helpful and collaborative tone.
-   If a change is particularly good, acknowledge it.

## Resources

-   **Tools:** `github-comment` (for posting feedback).
-   **Model:** Always use `zai/glm-5` for the core analysis phase of this skill.
