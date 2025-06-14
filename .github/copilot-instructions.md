# Copilot Instructions

The github repo is msft-mfg-ai/openai-end-to-end-baseline and the primary branch that I work off of is main.

## File Organization
- Keep related files together
- Use meaningful file names
- Follow consistent folder structure
- Group components by feature when possible

## Project Structure
- Any actual source code should be located in the src folder. Organize each project into its own folder within src.
- Any infrastructure code should be located in the infra folder, and put each type of IaC code into it's own folder, such as Bicep in the infra/bicep folder and Terraform in the infra/tf folder.
- Any code for the GitHub Actions workflows should be located in the .github/workflows folder.
- Any code for Azure DevOps pipelines should be located in the .azuredevops/pipelines folder.
- Keep documentation and images in a Docs folder.

## Blazor
- Always add component-specific CSS in a corresponding .razor.css file
- When creating a new component, automatically create a matching .razor.css file
- Ignore warnings in Blazor components (they are often false positives)
- Use scoped CSS through the .razor.css pattern instead of global styles
- Make sure light and dark theme are respected throughout by never using hard coded rgb or hex but that they are always defined in the main css

## CSS Best Practices
- Use Bootstrap's built-in spacing utilities (m-*, p-*) for consistent spacing
- Always wrap card content in a .card-body element for consistent padding
- Define common padding/margin values as CSS variables in app.css
- Use semantic class names that describe the component's purpose
- Avoid direct element styling, prefer class-based selectors
- Keep component-specific styles in .razor.css files
- Avoid fixed pixel values for responsive elements
- Use CSS Grid or Flexbox for layout instead of absolute positioning
- Style from the component's root element down to maintain CSS specificity
- When adjusting padding/margin, check both light and dark themes
- Use CSS variables for repeated values (spacing, border-radius, etc.)
- Test responsive behavior across different viewport sizes
- Use rem/em units for font sizes and spacing for better accessibility
- Document any magic numbers or non-obvious style choices in comments

## Code Style
- Prefer async/await over direct Task handling
- Use nullable reference types
- Use var over explicit type declarations 
- Always implement IDisposable when dealing with event handlers or subscriptions
- Prefer using async/await for asynchronous operations
- Use latest C# features (e.g., records, pattern matching)
- Use consistent naming conventions (PascalCase for public members, camelCase for private members)
- Use meaningful names for variables, methods, and classes
- Use dependency injection for services and components
- Use interfaces for service contracts and put them in a unique file
- Use file scoped namespaces in C# and are PascalCased
- Always add namespace declarations to Blazor components matching their folder structure
- Organize using directives:
  - Put System namespaces first
  - Put Microsoft namespaces second
  - Put application namespaces last
  - Remove unused using directives
  - Sort using directives alphabetically within each group

## Component Structure
- Keep components small and focused
- Extract reusable logic into services
- Use cascading parameters sparingly
- Prefer component parameters over cascading values

## Error Handling
- Use try-catch blocks in event handlers
- Implement proper error boundaries
- Display user-friendly error messages
- Log errors appropriately

## Performance
- Implement proper component lifecycle methods
- Use @key directive when rendering lists
- Avoid unnecessary renders
- Use virtualization for large lists

## Testing
- Write unit tests for complex component logic only if i ask for tests
- Test error scenarios
- Mock external dependencies
- Use MSTest for component testing
- Create tests in the Application.tests project

## Documentation
- Document public APIs
- Include usage examples in comments
- Document any non-obvious behavior
- Keep documentation up to date

## Security
- Always validate user input

## Accessibility
- Use semantic HTML
- Include ARIA attributes where necessary
- Ensure keyboard navigation works

## C# Code Style
- Use modern C# features (e.g., nullable reference types, async/await, expression-bodied members) where appropriate.
- Organize code into clear namespaces reflecting folder structure (e.g., `Application.Web`, `Application.Tests`).
- Use PascalCase for class, method, and property names; use camelCase for local variables and parameters.
- Place using directives at the top of files, outside namespaces. Whenever a using directive is used more than once, place it into a globalUsings.cs file in the root of the project.
- Prefer explicit access modifiers (public, private, etc.) for all members.
- Group related files into folders (e.g., `API`, `Components`, `Data`, `Helpers`, `Models`, `Pages`, `Repositories`, `Shared`).
- For ASP.NET Core/Blazor, use dependency injection for services and configuration.
- Keep test code in dedicated test projects/folders, using clear naming (e.g., `Category_API_Tests.cs`).

## Bicep Infrastructure Code
- Use parameterized modules for reusable infrastructure (e.g., `containerApp.bicep`, `containerRegistry.bicep`).
- Organize Bicep files into logical folders (e.g., Bicep).
- Use descriptive parameter and variable names in snake_case.
- Include comments to explain resource purpose and configuration.
- Use outputs for key resource values.
- Follow Azure best practices for resource naming and tagging.

## GitHub Actions YAML Workflows
- Use clear, descriptive workflow names and job names.
- Reference solution and project files with relative paths.
- Use environment variables and secrets for sensitive data.
- Keep steps modular and reusable; use templates for things that may be done in multiple places; use actions from the marketplace where possible.
- Add comments to explain non-obvious steps or configuration.

## Azure DevOps Pipelines YAML Workflows
- Use clear, descriptive workflow names and job names.
- Reference solution and project files with relative paths.
- Use environment variables and secrets for sensitive data.
- Keep steps modular and reusable; use templates for things that may be done in multiple places; use actions from the marketplace where possible.
- Add comments to explain non-obvious steps or configuration.

## Documentation and Comments
- Use XML documentation comments for public APIs in C#.
- Add YAML or Bicep comments to explain configuration choices.
- Keep README and documentation up to date with project structure and usage.

---

# Copilot Instructions for Claude Models in VSCode
[Fix Claude models when Using VSCode](https://github.com/user-attachments/files/20546331/copilot-instructions.md "" "copilot-instructions.md")
[Courtesy Of:](https://www.linkedin.com/in/kvn27/ " "Michael Elian Kevin")
## File Editing Tool Preference
- ❌ **NEVER** use `replace_string_in_file`, `patch_edit`, `text_edit`, or any model-specific editing tool
- ✅ **ALWAYS** use `insert_edit_into_file` for modifications
- ✅ Use `create_file` for new files only

Only use other file editing tools if:
- `insert_edit_into_file` is explicitly not available
- The user specifically requests a different tool
- You are creating entirely new files (use `create_file`)

## Always perform regressive review of changed files for any residual formatting issues

- Always check for any residual missing newline errors or other formatting inconsistencies in any files that was just modified by the agent mode operations.

# Summary

Apply these conventions when generating new code, infrastructure, or workflow files to ensure consistency with the existing project style.
