import { after, before, beforeEach, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, deleteDoc, doc, getDoc, getDocs, query, runTransaction, serverTimestamp, setDoc, updateDoc, where, writeBatch } from 'firebase/firestore';

let env;
const id = (uid, title = 'Dune', author = 'Frank Herbert') => {
  const hash = s => createHash('sha256').update(s.trim().toLowerCase()).digest('hex');
  return `${uid}__${hash(title)}_${hash(author)}`;
};
const book = (uid = 'alice', changes = {}) => ({
  id: id(uid), userId: uid, title: 'Dune', author: 'Frank Herbert', genre: 'Fiction',
  status: 'To Read', rating: null, notes: '', favorite: false, createdAt: serverTimestamp(), ...changes,
});
const db = uid => uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();
const ref = (database, data) => doc(database, 'books', data.id);

before(async () => { env = await initializeTestEnvironment({
  projectId: 'demo-bookshelf', firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
}); });
beforeEach(async () => env.clearFirestore());
after(async () => env?.cleanup());

test('owner can transact a new book, query, favorite, edit and delete', async () => {
  const database = db('alice'), data = book();
  await assertSucceeds(runTransaction(database, async tx => {
    const target = ref(database, data);
    const snapshot = await tx.get(target);
    if (!snapshot.exists()) tx.set(target, data);
  }));
  await assertSucceeds(getDocs(query(collection(database, 'books'), where('userId', '==', 'alice'))));
  await assertSucceeds(updateDoc(ref(database, data), {favorite: true, rating: 5, status: 'Finished'}));
  await assertSucceeds(deleteDoc(ref(database, data)));
});

test('anonymous and other users cannot access rows or forge an owner', async () => {
  const data = book();
  await setDoc(ref(db('alice'), data), data);
  for (const user of [null, 'bob']) {
    const database = db(user);
    await assertFails(getDoc(ref(database, data)));
    await assertFails(setDoc(ref(database, data), data));
    await assertFails(updateDoc(ref(database, data), {favorite: true}));
    await assertFails(deleteDoc(ref(database, data)));
  }
  await assertFails(getDocs(collection(db('alice'), 'books')));
  await assertFails(getDocs(collection(db(null), 'books')));
  await assertFails(updateDoc(ref(db('alice'), data), {userId: 'bob'}));
  await assertFails(setDoc(doc(db('alice'), 'other', 'x'), {userId: 'alice'}));
});

test('database rejects invalid values, including direct writes bypassing the form', async () => {
  const invalid = [
    {title: ''}, {title: '   '}, {title: 'a'.repeat(101)},
    {author: ''}, {author: '\t\n'}, {author: 'a'.repeat(61)},
    {genre: 'Fantasy'}, {status: 'Done'}, {rating: -1}, {rating: 6},
    {rating: 2.5}, {rating: '5'}, {notes: 'a'.repeat(301)}, {notes: null},
    {favorite: 'true'}, {createdAt: 'now'}, {id: 'random-id'}, {unexpected: true},
  ];
  for (const changes of invalid) {
    const data = book('alice', changes);
    if (!('id' in changes)) data.id = id(data.userId, data.title, data.author);
    await assertFails(setDoc(ref(db('alice'), data), data));
  }
  const valid = book('alice', {title: 'a'.repeat(100), author: 'b'.repeat(60), notes: 'n'.repeat(300), rating: 0});
  valid.id = id(valid.userId, valid.title, valid.author);
  await assertSucceeds(setDoc(ref(db('alice'), valid), valid));
  await assertFails(updateDoc(ref(db('alice'), valid), {rating: 7}));
  await assertFails(updateDoc(ref(db('alice'), valid), {createdAt: serverTimestamp()}));
});

test('optional rating/notes may be absent; canonical id prevents case variant duplicates', async () => {
  const data = book(); delete data.rating; delete data.notes;
  await assertSucceeds(setDoc(ref(db('alice'), data), data));
  for (const title of ['dune', 'DUNE', ' Dune ']) {
    const duplicate = book('alice', {title, id: 'arbitrary-second-document'});
    await assertFails(setDoc(ref(db('alice'), duplicate), duplicate));
  }
  const bob = book('bob', {title: 'dune'});
  await assertSucceeds(setDoc(ref(db('bob'), bob), bob));
});

test('rename atomically moves canonical id and cannot collide with another book', async () => {
  const database = db('alice'), first = book();
  await setDoc(ref(database, first), first);
  const old = (await getDoc(ref(database, first))).data();
  const renamed = {...old, title: 'Dune Messiah', id: id('alice', 'Dune Messiah')};
  const batch = writeBatch(database);
  batch.delete(ref(database, first)); batch.set(ref(database, renamed), renamed);
  await assertSucceeds(batch.commit());
  await assertFails(updateDoc(ref(database, renamed), {title: 'Other title'}));
});
