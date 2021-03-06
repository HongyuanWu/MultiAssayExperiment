### ==============================================
### MultiAssayExperiment constructor
### ----------------------------------------------

.generateMap <- function(mPheno, exlist) {
  samps <- lapply(exlist, colnames)
  listM <- lapply(seq_along(samps), function(i, x) {
    S4Vectors::DataFrame(assay = x[[i]], assayname = names(x)[i])
  }, x = samps)
  full_map <- do.call(S4Vectors::rbind, listM)
  matches <- match(full_map$assay, rownames(mPheno))
  if (all(is.na(matches))) {
    stop("no way to map pData to ExperimentList")
  }
  primary <- rownames(mPheno)[matches]
  autoMap <- S4Vectors::cbind(DataFrame(primary), full_map)
  if (any(is.na(autoMap$primary))) {
    notFound <- autoMap[is.na(autoMap$primary), ]
    warning("Data from rows:",
            sprintf("\n %s - %s", notFound[, 2], notFound[, 3]),
            "\ndropped due to missing phenotype data")
  }
  autoMap <- autoMap[!is.na(autoMap$primary), ]
  return(autoMap)
}

#' Create a MultiAssayExperiment object 
#'
#' This function combines multiple data elements from the different hierarchies
#' of data (study, experiments, and samples)
#' 
#' @param ExperimentList A \code{list} of all combined experiments
#' @param pData A \code{\link[S4Vectors]{DataFrame}} of the phenotype
#' data for all participants
#' @param sampleMap A \code{DataFrame} of sample identifiers, assay samples,
#' and assay names
#' @param drops A \code{list} of unmatched information
#' (included after subsetting)   
#' @return A \code{MultiAssayExperiment} data object that stores experiment
#' and phenotype data
#' 
#' @example inst/scripts/MultiAssayExperiment-Ex.R
#' 
#' @export MultiAssayExperiment
#' @seealso MultiAssayExperiment-class
MultiAssayExperiment <-
  function(ExperimentList = list(),
           pData = S4Vectors::DataFrame(),
           sampleMap = S4Vectors::DataFrame(),
           drops = list()) {
    newExperimentList <- ExperimentList(ExperimentList)
    if (!all(c(length(sampleMap) == 0L,
               length(pData) == 0L,
               length(newExperimentList) == 0L))) {
      if ((length(sampleMap) == 0L) && (length(pData) == 0L)) {
        warning("neither sampleMap nor pData provided,",
                " sampleMap will be generated")
        allsamps <- unique(unlist(lapply(newExperimentList, colnames)))
        pData <- S4Vectors::DataFrame(
          pheno1 = rep(NA, length(allsamps)),
          row.names = allsamps)
        sampleMap <- .generateMap(pData, newExperimentList)
      } else if ((length(sampleMap) == 0L) && (length(pData) != 0L)) {
        warning("sampleMap not provided, trying to generate sampleMap...")
        sampleMap <- .generateMap(pData, newExperimentList)
        validAssays <-
          S4Vectors::split(sampleMap[["assay"]], sampleMap[, "assayname"])
        newExperimentList <- Map(function(x, y) {
          x[, y]
        }, newExperimentList, validAssays)
        newExperimentList <- ExperimentList(newExperimentList)
      }
    }
    if (!is(pData, "DataFrame")) {
      pData <- S4Vectors::DataFrame(pData)
    }
    if (any(vapply(sampleMap, FUN = function(col) {
      !is.character(col)
    }, FUN.VALUE = logical(1L)))) {
      sampleMap[] <- lapply(sampleMap, as.character)
    }
    if (!is(sampleMap, "DataFrame")) {
      sampleMap <- S4Vectors::DataFrame(sampleMap)
    }
    newMultiAssay <- new("MultiAssayExperiment",
                         ExperimentList = newExperimentList,
                         pData = pData, 
                         sampleMap = sampleMap)
    return(newMultiAssay)
  }
