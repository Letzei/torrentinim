import db_sqlite
import strformat
import times
import strutils
import "./torrents/torrent"

proc insert_torrent*(torrent: Torrent): (bool, string) =
  ## echo &"{now()} [{torrent.source}] Attempting to insert torrent: {torrent.name}"

  let db = open("torrentinim-data.db", "", "", "")

  try:
    let id = db.insertID(sql"INSERT INTO torrents (uploaded_at, name, source, canonical_url, magnet_url, size, seeders, leechers) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
      torrent.uploaded_at,
      torrent.name,
      torrent.source,
      torrent.canonical_url,
      torrent.magnet_url,
      torrent.size,
      torrent.seeders,
      torrent.leechers
    )
    result = (true, $id)
  except DbError as e:
    result = (false, e.msg)
  finally:
    db.close()

proc searchTorrents*(query: string, page: int, order: string): seq[Torrent] =
  let limit = 20
  var offset = 0
  if page > 1:
    offset = (page - 1) * limit

  let db = open("torrentinim-data.db", "", "", "")
  var query = &"%{query}%" 
  query = dbQuote(query)
  let q = &"""
  SELECT name, source, uploaded_at, canonical_url, magnet_url, size, seeders, leechers
  FROM torrents
  WHERE name like {query}
  ORDER BY {order} DESC
  LIMIT {limit}
  OFFSET {offset}
  """
  let torrents = db.getAllRows(sql(q))
  
  for row in torrents:
    result.add(
      Torrent(
        name: row[0],
        source: row[1],
        uploaded_at: parse(row[2], "yyyy-MM-dd'T'HH:mm:sszzz"),
        canonical_url: row[3],
        magnet_url: row[4],
        size: row[5],
        seeders: parseInt(row[6]),
        leechers: parseInt(row[7]),
      )
    )
  db.close()
  
proc hotTorrents*(page: int): seq[Torrent] =
  let limit = 20
  var offset = 0
  if page > 1:
    offset = (page - 1) * limit

  let db = open("torrentinim-data.db", "", "", "")
  let torrents = db.getAllRows(sql"""
  SELECT name, source, uploaded_at, canonical_url, magnet_url, size, seeders, leechers
  FROM torrents
  WHERE datetime(uploaded_at) BETWEEN datetime('now', '-6 days', 'utc') AND datetime('now', 'utc')
  ORDER BY seeders DESC
  LIMIT ?
  OFFSET ?;
  """, limit, offset)
  
  for row in torrents:
    result.add(
      Torrent(
        name: row[0],
        source: row[1],
        uploaded_at: parse(row[2], "yyyy-MM-dd'T'HH:mm:sszzz"),
        canonical_url: row[3],
        magnet_url: row[4],
        size: row[5],
        seeders: parseInt(row[6]),
        leechers: parseInt(row[7]),
      )
    )
  db.close()
