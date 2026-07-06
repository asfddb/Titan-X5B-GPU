import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import fs from "fs";

const server = new Server(
  {
    name: "antigravity-mcp",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

const INBOX_FILE = "C:\\Users\\singb\\Downloads\\gpuuhj\\antigravity_inbox.txt";

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "ask_antigravity",
        description: "Send a message or request to the Antigravity AI agent. Antigravity monitors the inbox and can take actions in the codebase.",
        inputSchema: {
          type: "object",
          properties: {
            message: {
              type: "string",
              description: "The message or request for Antigravity",
            },
          },
          required: ["message"],
        },
      },
    ],
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  if (request.params.name === "ask_antigravity") {
    const message = request.params.arguments.message;
    const timestamp = new Date().toISOString();
    const logEntry = `[${timestamp}] Claude says: ${message}\n`;
    fs.appendFileSync(INBOX_FILE, logEntry);
    return {
      content: [
        {
          type: "text",
          text: `Message successfully sent to Antigravity's inbox at ${INBOX_FILE}. The user can tell Antigravity to check this inbox.`,
        },
      ],
    };
  }
  throw new Error("Tool not found");
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch(console.error);
