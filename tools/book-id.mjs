import { createHash } from 'node:crypto';
const [uid, title, author] = process.argv.slice(2);
if (!uid || !title?.trim() || !author?.trim()) {
  console.error('Usage: node tools/book-id.mjs USER_UID "Book title" "Book author"');
  process.exit(1);
}
const hash = s => createHash('sha256').update(s.trim().toLowerCase()).digest('hex');
console.log(`${uid}__${hash(title)}_${hash(author)}`);
