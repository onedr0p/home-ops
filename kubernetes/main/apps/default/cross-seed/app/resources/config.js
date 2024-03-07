// Note: Cross-Seed vars should be escaped with $${VAR_NAME} to avoid any interpolation by Flux
module.exports = {
  delay: 20,
  qbittorrentUrl: "http://qbittorrent.default.svc.cluster.local",
  torznab: [
    `http://prowlarr.default.svc.cluster.local/2/api?apikey=$${process.env.PROWLARR_API_KEY}`,  // avz
    `http://prowlarr.default.svc.cluster.local/8/api?apikey=$${process.env.PROWLARR_API_KEY}`,  // ptp
    `http://prowlarr.default.svc.cluster.local/11/api?apikey=$${process.env.PROWLARR_API_KEY}`, // btn
    `http://prowlarr.default.svc.cluster.local/20/api?apikey=$${process.env.PROWLARR_API_KEY}`, // tl
    `http://prowlarr.default.svc.cluster.local/26/api?apikey=$${process.env.PROWLARR_API_KEY}`, // mtv
    `http://prowlarr.default.svc.cluster.local/40/api?apikey=$${process.env.PROWLARR_API_KEY}`, // uhdb
    `http://prowlarr.default.svc.cluster.local/45/api?apikey=$${process.env.PROWLARR_API_KEY}`, // bhd
    `http://prowlarr.default.svc.cluster.local/47/api?apikey=$${process.env.PROWLARR_API_KEY}`, // ar
    `http://prowlarr.default.svc.cluster.local/48/api?apikey=$${process.env.PROWLARR_API_KEY}`, // ant
    `http://prowlarr.default.svc.cluster.local/49/api?apikey=$${process.env.PROWLARR_API_KEY}`, // athr
    `http://prowlarr.default.svc.cluster.local/84/api?apikey=$${process.env.PROWLARR_API_KEY}`, // nbl
  ],
  port: process.env.CROSSSEED_PORT || 80,
  apiAuth: false,
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
    "/media/Downloads/qbittorrent/complete/radarr",
    "/media/Downloads/qbittorrent/complete/sonarr",
  ],
  maxDataDepth: 1,
  outputDir: "/config/xseeds",
  torrentDir: "/config/qBittorrent/BT_backup",
};
