import std/json
import std/strutils
import httpClient
import times
import streams
import strformat
import strutils
import asyncdispatch
import "../torrents"
import "../torrents/torrent"

proc fetchJson*(query: string): string =
  let client = newAsyncHttpClient()
  ## The host and port should probably be made configurable here
  let json = waitfor client.getContent("http://localhost:8080/api/all/" & query.replace(" ", "%20"))
  client.close()
  return json

proc fetchLatest*(query: string) =
  echo &"{now()} [Tapi] Searching live for torrent on all sources"

  let json = fetchJson(query)
  let jsonNode = parseJson(json)
  let source_list = ["limetorrents","torrentgalaxy", "rarbg", "kickasstorrents", "nyaa", "eztv", "magnetdl", "torrentfunk", "glodls", "torrentproject2"]
 
  for site_torrent_list in jsonNode:
    for row in site_torrent_list:
      var torrent: Torrent = newTorrent()

      for source in source_list:
        if source in row{"Url"}.getStr():
          torrent.source = source

      if len(torrent.source) == 0:
        torrent.source = "Unknown"

      torrent.name = row{"Name"}.getStr()
      torrent.seeders = row{"Seeders"}.getInt()
      torrent.leechers = row{"leechers"}.getInt()
      torrent.size = row{"Size"}.getStr()
      torrent.canonical_url = row{"Torrent"}.getStr()
      torrent.magnet_url = row{"Torrent"}.getStr()

      if len(torrent.magnet_url) == 0 and len(torrent.canonical_url) == 0:
        continue

      let (insertSuccessful, msg) = insert_torrent(torrent)
  
      if insertSuccessful:
        echo &"{now()} [Tapi] Insert successful: {torrent.name}"
      ## else:
      ##  echo &"{now()} [Tapi] Insert not successful: {torrent.name} - {msg}"

proc liveSearch*(query: string) =
  try:
    fetchLatest(query)

  except:
    echo &"{now()} [Tapi] Failed to make live search..."
