# Coding Standards

This document outlines the coding standards and conventions used in the project. It serves as a reference for maintaining consistency across the codebase.

## Table of Contents
1. [Project Structure](#project-structure)
2. [Naming Conventions](#naming-conventions)
3. [Code Organization](#code-organization)
4. [Documentation](#documentation)
5. [Error Handling](#error-handling)
6. [Testing](#testing)
7. [Infrastructure as Code](#infrastructure-as-code)
8. [GitHub Actions](#github-actions)

## Project Structure

### Solution Organization
- **Application.Web:** Main web application project containing Blazor components, pages, and API controllers.
- **Application.Tests:** Test project containing unit and integration tests.

### Folder Structure
- **API/**: Contains API controllers with RESTful endpoints.
- **Components/**: Reusable Blazor UI components.
- **Data/**: Data models and constants.
- **Helpers/**: Utility and helper classes.
- **Models/**: Domain model classes and view models.
  - **Application/**: Application-specific models like AppSettings.
- **Pages/**: Blazor pages.
- **Repositories/**: Repository pattern implementation for data access.
  - **Interfaces/**: Repository interfaces.
- **Shared/**: Shared components and layouts.
- **wwwroot/**: Static assets (CSS, JS, images).

## Naming Conventions

### General
- Use **PascalCase** for:
  - Class names
  - Method names
  - Property names
  - Enum values
  - Constant names
- Use **camelCase** for:
  - Local variables
  - Method parameters
  - Private fields
- Use **UPPER_CASE** for:
  - Rarely-changed, app-wide constants

### File Naming
- Name files according to their primary class.
- **Razor Components:** `ComponentName.razor` with code-behind as `ComponentName.razor.cs`.
- **Tests:** Use descriptive names that indicate the tested component and type of test (e.g., `App_API_Tests.cs`).

### Interfaces
- Prefix interfaces with "I" (e.g., `IAppRepository`).

### Type Suffixes
- Controllers: `AppController`
- Repositories: `AppRepository`
- Tests: `App_API_Tests`

## Code Organization

### File Structure
- Begin each file with a copyright header comment.
- Include a summary comment explaining the file's purpose.
- Keep files focused on a single responsibility.

### Classes
- Organize class members in the following order:
  1. Fields
  2. Properties
  3. Constructors
  4. Public methods
  5. Private methods
- Use partial classes for code-behind files (e.g., Blazor components).
- Use Dependency Injection for accessing services.

### Regions (used sparingly)
- Use regions to organize large classes (e.g., `#region Initialization`).
- Don't overuse regions to hide poor code organization.

## Documentation

### Comments
- Use XML documentation comments for public APIs and classes.
- Use `<summary>` tags for method and class descriptions.
- Use `<param>` tags for parameters.
- Use `<returns>` tags for return values.

### Example
```csharp
/// <summary>
/// Retrieves a App by its unique identifier.
/// </summary>
/// <param name="id">The unique identifier of the App.</param>
/// <returns>The App if found; otherwise, null.</returns>
public App GetAppById(int id)
{
    // Implementation
}
```

## Error Handling

### Exceptions
- Use specific exception types rather than generic ones.
- Handle exceptions at the appropriate level of abstraction.
- Log exceptions properly with appropriate logging levels.
- Use custom exceptions where appropriate.

### Validation
- Validate inputs early in the process.
- Return appropriate status codes from API controllers.

## Testing

### Test Organization
- Organize tests by component and type.
- Use clear naming conventions:
  - `ClassName_MethodName_ExpectedBehavior`
  - Or category-based like `Category_API_Tests`

### Test Base Classes
- Use base classes like `BaseTest` and `BaseWebTest` for common test functionality.
- Separate test data from test logic using classes like `TestingDataManager`.

### Test Data
- Use dedicated test data classes (e.g., `TestingData_App`).
- Keep test data separate from test implementation.

## Conclusion

These standards are designed to ensure code consistency, readability, and maintainability across the project. Following these guidelines will help maintain code quality and make collaboration more effective.

---

*This document was generated based on the code analysis of the project as of May 28, 2025.*
