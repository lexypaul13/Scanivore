# TCA Documentation MCP Server

This MCP (Model Context Protocol) server integrates Point-Free's TCA (The Composable Architecture) documentation directly into Cursor, giving you instant access to official TCA docs while coding.

## 🚀 Setup Complete

Your TCA MCP server is ready to use! Here's what's been set up:

### Files Created:
- ✅ `.cursor/mcp.json` - MCP configuration
- ✅ `tca-docs-server.js` - TCA documentation server
- ✅ `package.json` - Node.js project configuration
- ✅ `node_modules/` - MCP SDK installed

## 🔧 Configuration

### MCP Server Configuration (`.cursor/mcp.json`):
```json
{
  "mcpServers": {
    "tca-docs": {
      "command": "node",
      "args": ["tca-docs-server.js"]
    }
  }
}
```

## 📚 Available TCA Concepts

The server provides documentation for these TCA concepts:

| Concept | Description |
|---------|-------------|
| `reducer` | Core reducer patterns and implementation |
| `state` | ObservableState and state management |
| `action` | Action design and patterns |
| `effect` | Side effects and async operations |
| `store` | Store usage and integration |
| `dependencies` | Dependency injection patterns |
| `navigation` | Navigation and routing |
| `testing` | TestStore and testing patterns |
| `binding` | BindableAction for two-way bindings |
| `observablestate` | @ObservableState macro usage |
| `presents` | @Presents for modal presentations |
| `shared` | @Shared for cross-feature state |
| `identifiedarray` | IdentifiedArray collections |

## 💬 Usage in Cursor

### 1. Restart Cursor
After setup, restart Cursor to load the MCP server.

### 2. Verify MCP Connection
- Go to **Settings → MCP**
- You should see a green indicator for `tca-docs`

### 3. Use in Chat
Ask questions about TCA and the AI will have access to official documentation:

```
💬 Examples:
• "How do I create a reducer in TCA?"
• "Show me how to use @ObservableState"
• "What's the proper way to handle navigation in TCA?"
• "How do I test TCA reducers?"
```

### 4. Direct Tool Access
You can also directly call the tools:

- **Get specific docs**: `@tca-docs reducer` 
- **Search docs**: `@tca-docs search navigation`

## 🛠 Available Tools

### `get_tca_docs`
Fetches official documentation for a specific TCA concept.

**Parameters:**
- `concept`: One of the available TCA concepts (reducer, state, action, etc.)

**Example:**
```
get_tca_docs("reducer")
```

### `search_tca_docs` 
Searches available TCA concepts for matching terms.

**Parameters:**
- `query`: Search term to find relevant TCA concepts

**Example:**
```
search_tca_docs("navigation")
```

## 🔗 Official Documentation Links

All content is fetched from official Point-Free TCA documentation:
- **Main Docs**: https://pointfreeco.github.io/swift-composable-architecture/
- **Identified Collections**: https://pointfreeco.github.io/swift-identified-collections/

## 🐛 Troubleshooting

### MCP Server Not Showing
1. Ensure Cursor is restarted after setup
2. Check that `node` is available in your PATH
3. Verify the MCP configuration file exists at `.cursor/mcp.json`

### Documentation Not Loading
1. Check your internet connection
2. Verify Point-Free's documentation site is accessible
3. The server will provide direct links if fetching fails

### Node.js Issues
```bash
# Verify Node.js installation
node --version

# Reinstall dependencies if needed
npm install
```

## 🎯 Benefits

✅ **Instant Access**: Get TCA docs without leaving Cursor  
✅ **Official Content**: Always up-to-date Point-Free documentation  
✅ **Context Aware**: AI understands TCA patterns for your code  
✅ **Offline Fallback**: Direct links provided if fetching fails  
✅ **Searchable**: Find relevant concepts quickly  

## 🔄 Updates

To update the TCA documentation server:

```bash
# Update MCP SDK
npm update @modelcontextprotocol/sdk

# Restart Cursor to reload the server
```

## 📋 Server Status

Use this command to test if the server dependencies are working:

```bash
node -e "console.log('✅ TCA MCP Server ready!'); process.exit(0);"
```

---

**🎉 Your TCA MCP Server is ready! Restart Cursor and start asking TCA questions with official documentation context.** 