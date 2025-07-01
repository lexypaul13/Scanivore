#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

const server = new Server(
  {
    name: 'tca-docs-minimal',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Simple tools list handler
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'test_tool',
        description: 'A simple test tool',
        inputSchema: {
          type: 'object',
          properties: {
            message: {
              type: 'string',
              description: 'Test message',
            },
          },
          required: ['message'],
        },
      },
    ],
  };
});

// Simple tool call handler
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  if (request.params.name === 'test_tool') {
    return {
      content: [
        {
          type: 'text',
          text: `Test response: ${request.params.arguments.message}`,
        },
      ],
    };
  }
  throw new Error(`Unknown tool: ${request.params.name}`);
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('Minimal MCP Server started successfully');
}

main().catch((error) => {
  console.error('Server error:', error);
  process.exit(1);
}); 