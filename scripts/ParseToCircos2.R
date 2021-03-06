library(dplyr, quietly = TRUE)
library(readxl, quietly = TRUE)
library(tidyr, quietly = TRUE)
library(argparser, quietly = TRUE)


plot.circos.labels <- function(all_patients = NULL, shared.links.circos = NULL, shared.links.circos.labels = NULL, title = NULL, filename = NULL) {
  options(warn = -1)
  library(circlize)
  library(RColorBrewer)
  library(GenomicRanges)
  library(data.table)

  plotcircos.cyto <- function(x, height, plotTypes, units, rotation, gap.width, labeltextchr, poslabelschr, heightlabelschr, marginlabelschr, data.CN) {
    circos.par("start.degree" = 90 - rotation, "gap.degree" = gap.width, cell.padding = c(0, 0, 0, 0), track.margin = c(0, 0))
    circos.genomicInitialize.new(x, plotType = plotTypes, unit = units)
    if (!is.null(data.CN) && ncol(data.CN) == 4 && labeltextchr == 1 && poslabelschr == "outer") {
      circos.genomicLabels(data.CN, labels.column = 4, connection_height = heightlabelschr, track.margin = c(0.01, marginlabelschr), side = "outside", cex = 0.45)
    }
    circos.genomicTrackPlotRegion(x, ylim = c(0, 1), bg.border = NA,
      track.height = height, panel.fun = function(region, value, ...) {
        col <- value[[2]]
        border <- value[[1]]
        circos.genomicRect(region, value, ybottom = 0,
          ytop = 1, col = col, border = border, ...)
        xlim <- get.cell.meta.data("xlim")
        circos.rect(xlim[1], 0, xlim[2], 1, border = "black")
      }, cell.padding = c(0, 0, 0, 0))
    if (!is.null(data.CN) && ncol(data.CN) == 4 && labeltextchr == 1 && poslabelschr == "inner") {
      circos.genomicLabels(data.CN, labels.column = 4, connection_height = heightlabelschr, track.margin = c(0.01, marginlabelschr), side = "inside")
    }
  }


  circos.genomicInitialize.new <-
    function(data, sector.names = NULL, major.by = NULL, unit = "", plotType, tickLabelsStartFromZero = TRUE, track.height = 0.05,
             ...) {
      if (is.factor(data[[1]])) {
        fa <- levels(data[[1]])
      }
      else {
        fa <- unique(data[[1]])
      }
      if (!is.null(sector.names)) {
        if (length(sector.names) != length(fa)) {
          stop("length of `sector.names` and length of sectors differ.")
        }
      }
      else {
        sector.names <- fa
      }
      names(sector.names) <- fa
      x1 <- tapply(data[[2]], data[[1]], min)[fa]
      x2 <- tapply(data[[3]], data[[1]], max)[fa]
      op <- circos.par("cell.padding")
      ow <- circos.par("points.overflow.warning")
      circos.par(cell.padding = c(0, 0, 0, 0), points.overflow.warning = FALSE, gap.after = 1, track.margin = c(0, 0))
      circos.initialize(factor(fa, levels = fa), xlim = cbind(x1,
        x2), ...)
      if (any(plotType %in% c("axis", "labels"))) {
        circos.genomicTrackPlotRegion(data, ylim = c(0, 1), bg.border = NA,
          track.height = track.height, panel.fun = function(region,
                                                            value, ...) {
            sector.index <- get.cell.meta.data("sector.index")
            xlim <- get.cell.meta.data("xlim")
            if (tickLabelsStartFromZero) {
              offset <- xlim[1]
              if (is.null(major.by)) {
                xlim <- get.cell.meta.data("xlim")
                major.by <- .default.major.by()
              }
              major.at <- seq(xlim[1], xlim[2], by = major.by)
              major.at <- c(major.at, major.at[length(major.at)] +
                major.by)
              if (major.by > 1e+06) {
                major.tick.labels <- paste((major.at - offset) / 1e+06,
                  "MB", sep = "")
              }
              else if (major.by > 1000) {
                major.tick.labels <- paste((major.at - offset) / 1000,
                  "KB", sep = "")
              }
              else {
                major.tick.labels <- paste((major.at - offset),
                  "bp", sep = "")
              }
            }
            else {
              if (is.null(major.by)) {
                xlim <- get.cell.meta.data("xlim")
                major.by <- .default.major.by()
              }
              major.at <- seq(floor(xlim[1] / major.by) * major.by,
                xlim[2], by = major.by)
              major.at <- c(major.at, major.at[length(major.at)] +
                major.by)
              if (major.by > 1e+06) {
                major.tick.labels <- paste(major.at / 1e+06,
                  "MB", sep = "")
              }
              else if (major.by > 1000) {
                major.tick.labels <- paste(major.at / 1000,
                  "KB", sep = "")
              }
              else {
                major.tick.labels <- paste(major.at, "bp",
                  sep = "")
              }
            }

            if (unit == "") {
              major.tick.labels <- gsub("[mkbp]", "", major.tick.labels, ignore.case = T)
            }

            if (all(c("axis", "labels") %in% plotType)) {
              # circos.axis(h = 0, major.at = major.at, labels = major.tick.labels,
              #            labels.cex = 0.49 * par("cex"), labels.facing = "clockwise",
              #            major.tick.percentage = 0.2)
              # circos.text(mean(xlim), 1.2, labels = sector.names[sector.index],
              #            cex = par("cex")-0.1, adj = c(0.5, -0.1*par("cex")*6-(par("cex")-1)*3), niceFacing = TRUE)
              circos.text(mean(xlim), 0.01, labels = sector.names[sector.index],
                cex = 3.5, adj = c(0.5, -0.1 * par("cex") * 6 - (par("cex") - 1) * 3), niceFacing = TRUE, font = 2)

            }
            else if ("labels" %in% plotType) {
              # circos.text(mean(xlim), 0, labels = sector.names[sector.index],
              # cex = par("cex")-0.1, adj = c(0.5, -0.1*par("cex")*6-(par("cex")-1)*3), niceFacing = TRUE)
              circos.text(mean(xlim), 0.5, labels = sector.names[sector.index],
                cex = 3, adj = c(0.5, -0.1 * par("cex") * 6 - (par("cex") - 1) * 3), niceFacing = TRUE)

            }
            else if ("axis" %in% plotType) {
              # circos.axis(h = 0, major.at = major.at, labels = major.tick.labels,
              #            labels.cex = 0.49 * par("cex"), labels.facing = "clockwise",
              #            major.tick.percentage = 0.2)
            }
          })
      }
      circos.par(cell.padding = op, points.overflow.warning = ow, track.margin = c(0, 0))
      return(invisible(NULL))
    }


  .default.major.by <- function(sector.index = get.cell.meta.data("sector.index"),
                                track.index = get.cell.meta.data("track.index")) {
    d <- circos.par("major.by.degree")
    cell.start.degre <- get.cell.meta.data("cell.start.degree", sector.index, track.index)
    tm <- reverse.circlize(c(cell.start.degre, cell.start.degre - d), rep(get.cell.meta.data("cell.bottom.radius", sector.index = sector.index, track.index = track.index), 2))
    major.by <- abs(tm[1, 1] - tm[2, 1])
    digits <- as.numeric(gsub("^.*e([+-]\\d+)$", "\\1", sprintf("%e", major.by)))
    major.by <- round(major.by, digits = -1 * digits)
    return(major.by)
  }

  get_most_inside_radius <- function() {
    tracks <- get.all.track.index()
    if (length(tracks) == 0) {
      1
    } else {
      n <- length(tracks)
      get.cell.meta.data("cell.bottom.radius", track.index = tracks[n]) - get.cell.meta.data("track.margin", track.index = tracks[n])[1] - circos.par("track.margin")[2]
    }
  }

  data.C.name <- "example_data_chromosome_cytoband.csv"
  # data.C <- data.frame(fread(data.C.name),stringsAsFactors=F)
  data.C <- as.data.frame(all_patients)
  data.C[, 2] <- as.numeric(data.C[, 2])
  data.C[, 3] <- as.numeric(data.C[, 3])
  data.T.file <- c("example_data_gene_label.csv")
  data.T <- lapply(1:length(data.T.file), function(x) {
    if (!is.null(data.T.file[x])) {
      # data.frame(fread(data.T.file[x]),stringsAsFactors=F)
    }
  })
  data.CN.name <- "example_data_gene_label.csv"
  data.CN <- NULL
  # data.CN <- data.frame(fread(data.CN.name),stringsAsFactors=F)
  if (!is.null(shared.links.circos.labels)) {
    data.CN <- as.data.frame(shared.links.circos.labels)
    data.CN[, 2] <- as.numeric(data.CN[, 2])
    data.CN[, 3] <- as.numeric(data.CN[, 3])
  }
  data.N.file <- c("", "", "", "", "", "", "", "", "", "")
  uploadtrack <- c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1)
  data.N <- lapply(1:10, function(x) {
    if (uploadtrack[x] == 2 && nchar(data.N.file[x]) > 0) {
      data.frame(fread(data.N.file[x]), stringsAsFactors = F)
    }
  })
  data.T <- NULL
  trackindx <- c()
  data.N <- data.N[trackindx]
  data.N <- NULL
  # data.L <- data.frame(fread("example_data_links.csv"),stringsAsFactors=F)
  data.L <- as.data.frame(shared.links.circos)
  data.L1 <- data.L[, 1:3]
  data.L2 <- data.L[, 4:6]
  data.L1[, 2] <- as.numeric(data.L1[, 2])
  data.L1[, 3] <- as.numeric(data.L1[, 3])
  data.L2[, 2] <- as.numeric(data.L2[, 2])
  data.L2[, 3] <- as.numeric(data.L2[, 3])
  data.L1$num <- 1:nrow(data.L1)
  data.L2$num <- 1:nrow(data.L2)
  rownames(data.L1) <- data.L1$num
  rownames(data.L2) <- data.L2$num
  for (i in 1:length(data.T.file)) {
    assign(paste("hltdata", i, sep = ""), "")
  }
  hltregion.List <- list()
  if (!is.null(data.T)) {
    for (k in 1:length(data.T)) {
      data.TT <- data.T[[k]]
      hltregion.List[[k]] <- ""
      if (nchar(get(paste("hltdata", k, sep = ""))) > 0) {
        tmp <- matrix(strsplit(get(paste("hltdata", k, sep = "")), "\n")[[1]])
        myColnames <- c("chr", "start", "end", "color")
        data <- matrix(0, length(tmp), length(myColnames))
        colnames(data) <- myColnames
        for (p in 1:length(tmp)) {
          myRow <- strsplit(tmp[p], ",")[[1]]
          if (length(myRow) == 4) {
            data[p, ] <- myRow
          }
        }
        data <- data.frame(data, stringsAsFactors = F)
        data$start <- as.numeric(data$start)
        data$end <- as.numeric(data$end)
        query <- GRanges(seqnames = data$chr, ranges = IRanges(start = data$start, end = data$end), seqinfo = NULL)
        subj <- GRanges(seqnames = data.TT[, 1], ranges = IRanges(start = data.TT[, 2], end = data.TT[, 3]), seqinfo = NULL)
        indx <- findOverlaps(query, subj)
        indx <- data.frame(indx, stringsAsFactors = F)
        indx$queryHits <- as.numeric(indx$queryHits)
        indx$subjectHits <- as.numeric(indx$subjectHits)
        hltregion <- data.TT[indx$subjectHits, ]
        hltregion$color <- data$color[indx[, 1]]
        hltregion$id <- paste(hltregion[, 1], hltregion[, 2], hltregion[, 3], sep = "")
        hltregion.List[[k]] <- hltregion
      }
    }
  }

  pdf(paste0(filename, ".pdf"), width = 750 / 72, height = 750 / 72)
  fontSize <- 1
  par(mar = c(0.6, 0.6, 0.6, 0.6), cex = fontSize - 0.05)
  trackChr <- "track"
  labelChr <- "labels"
  unitChr <- ""
  rotation <- 0.5
  gap.width <- 1
  if (length(unique(data.C[[1]])) > 6) {
    gap.width <- c(1, 1, 10, 1, 1, 1, 1, 1, 10, 1, 1)
  }
  labeltextchr <- 1
  poslabelschr <- "outer"
  heightlabelschr <- 0.05
  marginlabelschr <- 0.0001
  cexlabel <- 1
  heightChr <- 0.25
  plotcircos.cyto(data.C, height = heightChr, plotTypes = unique(c(labelChr, "axis")), units = unitChr, rotation = rotation, gap.width = gap.width, labeltextchr = labeltextchr, poslabelschr = poslabelschr, heightlabelschr = heightlabelschr, marginlabelschr = marginlabelschr, data.CN = data.CN)
  # title(title)
  marginLinks <- 0.01
  circos.par(track.margin = c(0, marginLinks))
  transparencyLinks <- 0.5
  rou <- get_most_inside_radius()
  rou <- rou[1]
  data.L1 <- data.L1[, c(1:3)]
  data.L2 <- data.L2[, c(1:3)]
  linkscolor.export <- c("#00000050")
  linkscolor.export <- data.L[[7]]
  circos.genomicLink(data.L1, data.L2, rou = rou, col = linkscolor.export, border = NA)
  dev.off()


  svglite::svglite(paste0(filename, ".svg"), width = 750 / 72, height = 750 / 72)
  plotcircos.cyto(data.C, height = heightChr, plotTypes = unique(c(labelChr, "axis")), units = unitChr, rotation = rotation, gap.width = gap.width, labeltextchr = labeltextchr, poslabelschr = poslabelschr, heightlabelschr = heightlabelschr, marginlabelschr = marginlabelschr, data.CN = data.CN)
  # title(title)
  circos.par(track.margin = c(0, marginLinks))

  circos.genomicLink(data.L1, data.L2, rou = rou, col = linkscolor.export, border = NA)
  dev.off()

}


parse_strict <- function(file) {
  data <- read_excel(file, skip = 1)
  # remove NAs
  data <- data[complete.cases(data[, c(1, 2)]), ]
  patient <- gsub("(\\S+?)\\_.*", "\\1", basename(file))
  data$patient <- patient
  data <- data %>%
    dplyr::group_by(cluster_id) %>%
    select(patient, cluster_id, num_seqs, V_CALL...4, J_CALL...6, V_CALL...16, J_CALL...18, V_CALL...28, J_CALL...30) %>%
    unique()
  data$end <- cumsum(data$num_seqs)
  data$start <- c(1, head(data$end, -1))
  n_clones <- sum(data$num_seqs > 1)
  data$color <- "#FFFFFF"
  data$border <- NA
  if (n_clones > 0) {
    data$color[1:n_clones] <- c("#000000", gray.colors(n_clones - 1))
    data$border[1:n_clones] <- "#000000"
  }

  data <- data %>% select(patient, start, end, border, color, cluster_id, num_seqs, V_CALL...4, J_CALL...6, V_CALL...16, J_CALL...18, V_CALL...28, J_CALL...30)
  return(data)
}


create_links <- function(data) {
  column.vector.by.patient <- data %>%
    mutate(combo = paste(patient, start, end, border, color, cluster_id, num_seqs, key, patcluster, sep = "|")) %>%
    pull(combo)

  pairwise.list <- combn(column.vector.by.patient, 2, simplify = F)

  deflate_vector_to_df <- function(vector.pair) {
    string <- paste0(vector.pair, collapse = "|")
    columns.vector <- strsplit(string, "\\|", perl = T)[[1]]
    return(columns.vector)
  }

  out.df <- as.data.frame(do.call(rbind, lapply(pairwise.list, deflate_vector_to_df)))
  header <- c("patient", "start", "end", "border", "color", "cluster_id", "num_seqs", "key", "patcluster")
  colnames(out.df) <- c(paste0(header, "1"), paste0(header, "2"))
  return(out.df)
}


create_circos_plot <- function(files = NULL, filename = NULL, linklabels = TRUE, sample_order = NULL) {
  patient_list <- NULL
  all_patients <- NULL
  shared <- NULL
  shared_V_only <- NULL
  title <- NULL


  title <- "Strict Criteria (V+J)"

  patient_list <- lapply(files, parse_strict)
  all_patients <- bind_rows(patient_list) %>% mutate(patcluster = paste(patient, cluster_id, sep = ","))

  # order patients
  if (! is.null(sample_order)){
    order.vector = strsplit(sample_order, split=",")
    order.vector = as.character(order.vector[[1]])
    if (unique(all_patients$patient) %in% order.vector){
        all_patients$patient <- factor(all_patients$patient, levels = order.vector)
    }
    #print(head(all_patients$patient))
  }

  shared <- all_patients %>% group_by(V_CALL...4, J_CALL...6, V_CALL...16, J_CALL...18, V_CALL...28, J_CALL...30) %>% add_tally() %>% filter(n > 1) %>% mutate(key = paste(V_CALL...4, J_CALL...6, V_CALL...16, J_CALL...18, V_CALL...28, J_CALL...30, sep = ","))

  # Manual colors defined by davide
  all_patients$color[which(all_patients$patcluster == "COV47,6" | all_patients$patcluster == "COV21,1")] <- "#ff2500ff"
  # patient 57 has a differente VH allele
  all_patients$color[which(all_patients$patcluster == "COV21,6" | all_patients$patcluster == "COV57,6" | all_patients$patcluster == "COV107,7")] <- "#0432ffff"
  all_patients$color[which(all_patients$patcluster == "COV21,4" | all_patients$patcluster == "COV72,5")] <- "#ff9300ff"
  all_patients$color[which(all_patients$patcluster == "COV72,8" | all_patients$patcluster == "COV107,15")] <- "#fefb00ff"

  shared.links <- shared %>% group_modify(~ create_links(.x))

  # Links colors
  shared.links$color <- "#00000045"
  shared.links$color[which(shared.links$num_seqs1 > 1 & shared.links$num_seqs2 > 1)] <- "purple"
  shared.links$color[which((shared.links$num_seqs1 > 1 & shared.links$num_seqs2 == 1) | (shared.links$num_seqs1 == 1 & shared.links$num_seqs2 > 1))] <- "green"

  shared.links.circos <- as.data.frame(shared.links) %>% select(patient1, start1, end1, patient2, start2, end2, color)

  shared.links.circos.labels <- NULL
  if (linklabels == TRUE) {
    shared.links.circos.labels <- as.data.frame(shared) %>% select(patient, start, end, key)
    shared.links.circos.labels$key <- gsub("\\,NA", "", shared.links.circos.labels$key, perl = TRUE)
    shared.links.circos.labels$key <- gsub("(\\S+IGHJ\\S+)\\,(IG[KL]V\\S+)", "\\1\n\\2", shared.links.circos.labels$key, perl = TRUE)
  }

  plot.circos.labels(all_patients, shared.links.circos, shared.links.circos.labels, title, filename)

}


main <- function() {
  # Create a parser
  p <- arg_parser("Parse IgParse.pl output and creat Circos plots")

  # Add command line arguments
  p <- add_argument(p, "--input_dir", help = "directory where the excel files are located")
  p <- add_argument(p, "--output_prefix", help = "output prefix")
  p <- add_argument(p, "--sample_order", help = "sample order")

  # Parse the command line arguments
  argv <- parse_args(p)

  # check if input and codefile arguments are not NA
  if (is.na(argv$input_dir) || is.na(argv$output_prefix)) {
    print(p)
    quit()
  }

  # For strict files COV
  files <- list.files(pattern = ".*strict_selected_columns.xlsx", path = argv$input_dir, full.names = T)
  create_circos_plot(files, filename = paste0(argv$output_prefix, "/clusters_strict_criteria"), linklabels = TRUE, sample_order = argv$sample_order)
  create_circos_plot(files, filename = paste0(argv$output_prefix, "/clusters_strict_criteria_nolabels"), linklabels = FALSE, sample_order = argv$sample_order)
}


# Call main function
main()
