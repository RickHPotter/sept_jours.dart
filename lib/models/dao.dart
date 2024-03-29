import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';

import 'package:flutter_webapi_first_course/database/database.dart';
import 'package:uuid/uuid.dart';
import '../services/journal_services.dart';
import 'journal.dart';

class Dao {
  static Logger log = Logger();

  static Map<String, int> actions = {
    'DELETE' : -1,
    'NOUGHT' :  0,
    'INSERT' :  1,
    'UPDATE' :  2,
  };

  static const String
    _tableName = 'journalTable',

    _id = 'id',
    _hash = 'hash',
    _title = 'title',
    _content = 'content',
    _createdAt = 'createdAt',
    _updatedAt = 'updatedAt';

  static DataBaseHelper dbHelper = DataBaseHelper();

  static const String tableSQL =
      'CREATE TABLE $_tableName ('
      '$_id INTEGER, '
      '$_hash TEXT PRIMARY KEY, '
      '$_title TEXT, '
      '$_content TEXT, '
      '$_createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, '
      '$_updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)';

  static List<Journal> toList(List<Map<String, dynamic>> journalsMap) {
    log.i('[DAO] [toList] Parsing Map into List...');
    final List<Journal> journals = [];
    for (Map<String, dynamic> line in journalsMap) {
      final Journal journal = Journal(
        id: line[_id].toString(),
        hash: line[_hash],
        title: line[_title],
        content: line[_content],
        createdAt: DateTime.parse(line[_createdAt]),
        updatedAt: DateTime.parse(line[_updatedAt]),
      );
      journals.add(journal);
    }
    log.i('[DAO] [toList] Journals List has been created with size ${journals.length}.');
    return journals;
  }

  static Map<String, dynamic> toMap(Journal journal, int action) {
    log.i('[DAO] [toMap] Parsing Journal ${journal.hash} into Map...');

    final Map<String, dynamic> journalMap = {};

    journalMap.addAll({
      _id: action,
      _hash: journal.hash,
      _title: journal.title,
      _content: journal.content,
      _createdAt: journal.createdAt.toString(),
      _updatedAt: journal.updatedAt.toString(),
    });

    log.i('[DAO] [toMap] JournalsMap of ${journal.hash} has been created.');

    return journalMap;
  }

  /*
  DEV INTERFACE
  */

  // READ
  static Future<List<Journal>> orderedGet() async {
    final Database db = await dbHelper.initDB('findAll');
    final List<Map<String, dynamic>> journals = await db.query(
      _tableName,
      where: '$_id IN (?, ?, ?) order by $_createdAt desc',
      whereArgs: [0, 1, 2],
    );

    log.i('[DAO] [orderedGet] Found journals of length ${journals.length}.');
    return toList(journals);
  }

  static Future<List<Journal>> findAll(List<int> listId) async {
    String inClause = '';
    inClause = '?, ' * (listId.length - 1);
    inClause = '$inClause ?';

    final Database db = await dbHelper.initDB('findAll');
    final List<Map<String, dynamic>> journals = await db.query(
      _tableName,
      where: '$_id IN ($inClause)',
      whereArgs: [...listId],
    );

    log.i('[DAO] [findAll] Found journals of length ${journals.length}.');
    return toList(journals);
  }

  static Future<List<Journal>> find(String journalHash) async {
    final Database db = await dbHelper.initDB('find');

    final List<Map<String, dynamic>> journals = await db.query(
      _tableName,
      where: '$_hash = ? and $_id >= ?',
      whereArgs: [journalHash, 0],
      limit: 1,
    );

    log.i('[DAO] [find] Found journal $journalHash.');
    return toList(journals);
  }

  // CREATE
  static Future<bool> insert(Journal journal, {String action = 'NOUGHT'}) async {
    final Database db = await dbHelper.initDB('[CREATE]');

    int result = 0;
    List<Journal> itemExists = await find(journal.hash);
    if (itemExists.isEmpty) {
      result = await db.insert(
          _tableName,
          toMap(journal, actions[action]!),
      );
      log.i('[DAO] [CREATE] Journal ${journal.hash} has been inserted.');
    }
    else {
      log.i('[DAO] [CREATE] Journal ${journal.hash} already exists.');
    }
    return (result > 0);
  }

  static insertBatch(List<Journal> list, {String action = 'NOUGHT'}) async {
    final Database db = await dbHelper.initDB('[CREATE BATCH]');

    // not checking if it exists means less db operations, but is it safe?
    Batch batch = db.batch();
    for (Journal journal in list) {
      batch.insert(
        _tableName,
        toMap(journal, actions[action]!),
      );
    }
    batch.commit(noResult: true);
    log.i('[DAO] [CREATE] ${list.length} Journals have been attempted to be inserted.');
  }

  // UPDATE
  static Future<bool> update(Journal journal, {String action = 'NOUGHT'}) async {
    final Database db = await dbHelper.initDB('[UPDATE]');

    var res = await db.update(
      _tableName,
      toMap(journal, actions[action]!),
      where: '$_hash = ?',
      whereArgs: [journal.hash],
    );
    return (res > 0);
  }

  // DELETE
  static delete(String journalHash, {int id = -1}) async {
    final Database db = await dbHelper.initDB('[DELETE]');
    return await db.delete(
      _tableName,
      where: '$_hash = ? and $_id = ?',
      whereArgs: [journalHash, id],
    );
  }

  /*
  USER INTERFACE
  */

  static prepareForInsert(Journal journal) async {
    final Database db = await dbHelper.initDB('[CREATE]');

    Map<String, dynamic> journalsMap = toMap(journal, actions['INSERT']!);

    int result = 0;
    var itemExists = await find(journal.hash);
    if (itemExists.isEmpty) {
      result = await db.insert(_tableName, journalsMap);
      log.i('[DAO] [CREATE] Journal ${journal.hash} has been inserted.');
    }
    else {
      log.i('[DAO] [CREATE] ${journal.hash} already in use. Creating a new one.');
      journal.hash = journal.hash.split(".H.")[0] + const Uuid().v1();
      prepareForInsert(journal);
    }
    return (result > 0);
  }

  static prepareForUpdate(Journal journal) async {
    final Database db = await dbHelper.initDB('[UPDATE]');

    final List<Map<String, dynamic>> j = await db.rawQuery(
      'SELECT ID FROM $_tableName WHERE HASH = ?',
      [journal.hash]
    );

    String action;
    (j[0][_id] == 1) ? action = 'INSERT' : action = 'UPDATE'; // BEWARE OF -1

    return update(journal, action: action);
  }

  static prepareForDelete(Journal journal) async {
    final Database db = await dbHelper.initDB('[UPDATE]');

    final List<Map<String, dynamic>> j = await db.rawQuery(
        'SELECT ID FROM $_tableName WHERE HASH = ?',
        [journal.hash]
    );

    if (j[0][_id] == 1) { // if 1, then it's only in the db
      delete(journal.hash, id: 1);
      return true;
    }

    return update(journal, action: 'DELETE');
  }

  static Future<Map<String, Journal>> refreshFromDB() async {
    Map<String, Journal> database = {};
    await Dao.findAll([0, 1, 2])
        .then((list) => database = {for (var e in list) e.hash: e})
        .catchError((error) => error);
    return database;
  }

  static retrieveFromAPI() async {
    JournalService service = JournalService();

    // ! Firstly, all data from the DB goes to the API
    List<Journal> pendingDelete = await Dao.findAll([-1]);
    for (Journal journal in pendingDelete) {
      await service.delete(journal.hash)
          .then((value) async => (value) ? await Dao.delete(journal.hash) : null)
          .catchError((error) => error);
    }

    List<Journal> pendingInsert = await Dao.findAll([1]);
    for (Journal journal in pendingInsert) {
      await service.post(journal)
          .then((value) async => (value) ? await Dao.update(journal) : null)
          .catchError((error) => error);
    }

    List<Journal> pendingUpdate = await Dao.findAll([2]);
    for (Journal journal in pendingUpdate) {
      await service.patch(journal)
          .then((value) async => (value) ? await Dao.update(journal) : null)
          .catchError((error) => error);
    }

    // ! Secondly, all data from API comes to the DB
    List<Journal> list = await service.getAll().catchError((error) => error);
    await Dao.insertBatch(list);
  }
}