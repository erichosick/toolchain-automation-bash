# My Markdown Manipulation Package

## Description
This package contains a set of Bash functions designed for manipulating content within Markdown files. It includes functions for adding content, clearing content, sorting content, and adding new token markers in a structured and controlled manner.


Anything added to the tools directory will automatically be sourced. See project_create.sh.

## Functions

### 1. token_add_content
**Purpose**:  
Adds content at a specified location within a Markdown file based on the provided token and direction.

**Parameters**:  
- `file_path`: Path to the Markdown file.
- `token`: Token around which content is to be added.
- `direction`: Determines where to add the content ('above' or 'below').
- `content`: Content to be added. If not provided, it will be read from stdin.

**Usage**:  
```bash
token_add_content README.md TITLE above "New content"
echo "New content" | token_add_content README.md TITLE above
```

**Behavior**
Inserts the given content either directly above or below the specified token in the file.

### 2. token_clear

**Purpose**
Clears content between specified start and end tokens in a Markdown file.

**Parameters**

- `file_path`: Path to the Markdown file.
- `token`: Token whose content is to be cleared.

**Usage**

```bash
# README.md would containt <!-- DESCRIPTION_START>
token_clear README.md DESCRIPTION
```
**Behavior**
Removes all content contained in the TOKEN.


### 3. token_sort

**Purpose**
Sorts content alphabetically between specified start and end tokens in a Markdown file.

**Parameters**

- `file_path`: Path to the Markdown file.
- `token`: Token within which content is to be sorted.

**Usage**

```
token_sort README.md CONTRIBUTORS
```

**Behavior**
Alphabetically sorts lines of content for the given TOKEN.



### 4. token_new

**Purpose**
Adds new custom token markers into a Markdown file after an existing specified token.

**Parameters**

- `file_path`: Path to the Markdown file.
- `existing_token`: Existing token after which new tokens will be added.
- `new_token`: New token to be added.

**Usage**

```
token_new README.md BADGES TABLE_OF_CONTENTS
```

**Behavior**
Inserts new start and end tokens for the specified new token immediately following the end token of the existing token.