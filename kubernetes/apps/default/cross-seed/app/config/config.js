module.exports = {
  delay: 20,
  qbittorrentUrl: "http://qbittorrent.default.svc.cluster.local",
  torznab: [
    "http://prowlarr.default.svc.cluster.local/2/api?apikey={{ .PROWLARR__API_KEY }}",  // avz
    "http://prowlarr.default.svc.cluster.local/8/api?apikey={{ .PROWLARR__API_KEY }}",  // ptp
    "http://prowlarr.default.svc.cluster.local/11/api?apikey={{ .PROWLARR__API_KEY }}", // btn
    "http://prowlarr.default.svc.cluster.local/20/api?apikey={{ .PROWLARR__API_KEY }}", // tl
    "http://prowlarr.default.svc.cluster.local/21/api?apikey={{ .PROWLARR__API_KEY }}", // blu
    "http://prowlarr.default.svc.cluster.local/26/api?apikey={{ .PROWLARR__API_KEY }}", // mtv
    "http://prowlarr.default.svc.cluster.local/40/api?apikey={{ .PROWLARR__API_KEY }}", // uhdb
    "http://prowlarr.default.svc.cluster.local/42/api?apikey={{ .PROWLARR__API_KEY }}", // phd
    "http://prowlarr.default.svc.cluster.local/45/api?apikey={{ .PROWLARR__API_KEY }}", // bhd
    "http://prowlarr.default.svc.cluster.local/47/api?apikey={{ .PROWLARR__API_KEY }}", // ar
    "http://prowlarr.default.svc.cluster.local/48/api?apikey={{ .PROWLARR__API_KEY }}", // ant
    "http://prowlarr.default.svc.cluster.local/49/api?apikey={{ .PROWLARR__API_KEY }}", // athr
    "http://prowlarr.default.svc.cluster.local/84/api?apikey={{ .PROWLARR__API_KEY }}", // nbl
  ],
  action: "inject",
  includeEpisodes: false,
  includeSingleEpisodes: true,
  includeNonVideos: true,
  duplicateCategories: true,
  matchMode: "safe",
  skipRecheck: true,
  linkType: "hardlink",
  linkDir: "/media/Downloads/qbittorrent/complete/cross-seed",
  dataDirs: [
    "/media/Downloads/qbittorrent/complete/prowlarr",
    "/media/Downloads/qbittorrent/complete/radarr",
    "/media/Downloads/qbittorrent/complete/sonarr",
  ],
  maxDataDepth: 1,
  outputDir: "/config/xseeds",
  torrentDir: "/config/qBittorrent/BT_backup",
};
