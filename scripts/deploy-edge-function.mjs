import fs from "node:fs";
import path from "node:path";

const projectRef = "rojczcqkxdwjmxxxfdau";
const tokenPath = path.join(process.env.USERPROFILE ?? "", ".supabase", "access-token");
const token = fs.readFileSync(tokenPath, "utf8").trim();

const slug = process.argv[2];
if (!slug) {
  console.error("Usage: node scripts/deploy-edge-function.mjs <function-slug>");
  process.exit(1);
}

const root = path.resolve("supabase/functions");
const entry = path.join(root, slug, "index.ts");
const files = [entry];

function collectSharedImports(filePath, seen = new Set()) {
  const content = fs.readFileSync(filePath, "utf8");
  for (const match of content.matchAll(/from\s+["'](\.\.?\/[^"']+)["']/g)) {
    const rel = match[1];
    const resolved = path.resolve(path.dirname(filePath), rel);
    const withTs = resolved.endsWith(".ts") ? resolved : `${resolved}.ts`;
    if (!seen.has(withTs) && fs.existsSync(withTs)) {
      seen.add(withTs);
      files.push(withTs);
      collectSharedImports(withTs, seen);
    }
  }
}

collectSharedImports(entry, new Set([entry]));

const form = new FormData();
form.append(
  "metadata",
  JSON.stringify({
    entrypoint_path: `${slug}/index.ts`,
    name: slug,
    verify_jwt: false,
  }),
);

for (const filePath of files) {
  const rel = path.relative(root, filePath).replace(/\\/g, "/");
  form.append("file", new Blob([fs.readFileSync(filePath)]), rel);
}

const response = await fetch(
  `https://api.supabase.com/v1/projects/${projectRef}/functions/deploy?slug=${slug}`,
  {
    method: "POST",
    headers: { Authorization: `Bearer ${token}` },
    body: form,
  },
);

const text = await response.text();
console.log(response.status, text);
if (!response.ok) process.exit(1);
