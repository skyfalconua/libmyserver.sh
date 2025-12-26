# Agent Instructions

Please adhere to the following rules when modifying or analyzing this codebase:

1.  **No Shebangs in Library Files**: Do not add shebang lines (e.g., `#!/bin/bash`) to any shell scripts located in the `lib/` directory. These files are intended to be sourced, not executed directly.
2.  **Build Process**: Run `bash build.sh` to generate the final concatenated or processed output with full context.
3.  **Consistency Check**: After running the build, verify the `_dist/libmyserver.sh` file for logical consistency and to ensure the build succeeded as expected.
4.  **Shell Variable Declarations**: In shell scripts, do not split variable declaration and assignment. Perform them on a single line.
    *   **Correct**: `local var="value"` or `readonly var="value"`
    *   **Incorrect**:
        ```bash
        local var
        var="value"
        ```
