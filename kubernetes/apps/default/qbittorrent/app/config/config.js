module.exports = {
  delay: 30,

  torznab: [
    "http://prowlarr.default.svc.cluster.local/2/api?apikey={{ .PROWLARR__API_KEY }}",  // avz
    "http://prowlarr.default.svc.cluster.local/11/api?apikey={{ .PROWLARR__API_KEY }}", // btn
    "http://prowlarr.default.svc.cluster.local/20/api?apikey={{ .PROWLARR__API_KEY }}", // tl
    "http://prowlarr.default.svc.cluster.local/26/api?apikey={{ .PROWLARR__API_KEY }}", // mtv
    "http://prowlarr.default.svc.cluster.local/6/api?apikey={{ .PROWLARR__API_KEY }}",  // st
    "http://prowlarr.default.svc.cluster.local/21/api?apikey={{ .PROWLARR__API_KEY }}", // blu
    "http://prowlarr.default.svc.cluster.local/8/api?apikey={{ .PROWLARR__API_KEY }}",  // ptp
    "http://prowlarr.default.svc.cluster.local/1/api?apikey={{ .PROWLARR__API_KEY }}",  // fl
  ],

  action: "inject",
  matchMode: "safe",
  skipRecheck: true,
  includeEpisodes: true,
  includeNonVideos: true,
  duplicateCategories: true,
  outputDir: "/config/cross-seed",
  torrentDir: "/config/qBittorrent/BT_backup",
  qbittorrentUrl: "http://localhost",
  rssCadence: "15 minutes", // autobrr doesnt get every announcement
};
