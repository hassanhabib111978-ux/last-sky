# LAST SKY — MCP Setup

## Goal
Connect an AI coding agent to the Godot editor so project inspection, editing and verification can happen through the editor instead of requiring the project owner to copy large code blocks manually.

## Current status
The GitHub connection is active and can modify this repository. A live Godot-editor MCP connection is not yet established in this ChatGPT session.

## Safety
- Do not expose a local MCP endpoint directly to the public internet.
- Prefer localhost or a protected private connection.
- Use authentication/token support when the selected MCP implementation provides it.
- Keep destructive operations behind explicit approval.

## Next verification gates
1. Confirm the Godot version available for the phone workflow.
2. Confirm the selected Godot MCP implementation and its Android/remote limitations.
3. Establish the editor connection.
4. Inspect the live project.
5. Only then generate engine-specific scenes, scripts and assets.
