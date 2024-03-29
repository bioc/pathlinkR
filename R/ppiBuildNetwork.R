#' Construct a PPI network from input genes and InnateDB's database
#'
#' @param rnaseqResult An object of class "DESeqResults", "TopTags", or a simple
#' data frame. See Details for more information on input types.
#' @param filterInput If providing list of data frames containing the
#'   unfiltered output from `DESeq2::results()`, set this to TRUE to filter for
#'   DE genes using the thresholds set by the `pCutoff` and `fcCutoff`
#'   arguments. When FALSE it's assumed your passing the filtered
#'   results into `inputList` and no more filtering will be done.
#' @param columnFC Character; optional column containing fold change values,
#'   used only when `filterInput=TRUE` and the input is a data frame.
#' @param columnP Character; optional column containing p values, used only
#'   when `filterInput=TRUE` and the input is a data frame.
#' @param pCutoff Adjusted p value cutoff, defaults to <0.05
#' @param fcCutoff Absolute fold change cutoff, defaults to an absolute value
#'   of >1.5
#' @param order Desired network order. Possible options are "zero" (default),
#'   "first," "minSimple."
#' @param hubMeasure Character denoting what measure should be used in
#'   determining which nodes to highlight as hubs when plotting the network.
#'   Options include "betweenness" (default), "degree", and "hubscore". These
#'   represent network statistics calculated by their respective
#'   `tidygraph::centrality_x`, functions.
#' @param ppiData Data frame of PPI data; must contain rows of interactions as
#'   pairs of Ensembl gene IDs, with columns named "ensemblGeneA" and
#'   "ensemblGeneB". Defaults to pre-packaged InnateDB PPI data.
#'
#' @return A Protein-Protein Interaction (PPI) network; a "tidygraph" object for
#'   plotting or further analysis, with the minimum set of columns for nodes
#'   (additional columns from the input will also be included):
#'   \item{name}{Ensembl gene ID for the node}
#'   \item{degree}{Degree of the node, i.e. the number of interactions}
#'   \item{betweenness}{Betweenness measure for the node}
#'   \item{seed}{TRUE when the node was part of the input list of genes}
#'   \item{hubScore}{Special hubScore for each node. The suffix denotes the
#'   measure being used; e.g. "hubScoreBtw" is for betweenness}
#'   \item{hgncSymbol}{HGNC gene name for the node}
#'
#' Additionally the following columns are provided for edges:
#'   \item{from}{Starting node for the interaction/edge as a row number}
#'   \item{to}{Ending node for the interaction/edge as a row number}
#'
#' @export
#'
#' @import dplyr
#'
#' @importFrom stringr str_wrap
#' @importFrom tibble rownames_to_column
#' @importFrom tidygraph activate as_tbl_graph centrality_betweenness
#'   centrality_degree centrality_hub
#'
#' @description Creates a protein-protein interaction (PPI) network using
#'   data from InnateDB, with options for network order, and filtering input.
#'
#' @details The input to `ppiBuildNetwork()` can be a "DESeqResults" object
#'   (from `DESeq2`), "TopTags" (`edgeR`), or a simple data frame.
#'   When not providing a basic data frame, the columns for filtering are
#'   automatically pulled ("log2FoldChange" and "padj" for DESeqResults, or
#'   "logFC" and "FDR" for TopTags). Otherwise, the arguments "columnFC" and
#'   "columnP" must be specified.
#'
#'   The "hubMeasure" argument determines how `ppiBuildNetwork` assesses
#'   connectedness of nodes in the network, which will be used to highlight
#'   nodes when visualizing with `ppiPlotNetwork`. The options are "degree",
#'   "betweenness", or "hubscore". This last option uses the igraph
#'   implementation of the Kleinburg hub centrality score - details on this
#'   method can be found at `?igraph::hub_score`.
#'
#' @references InnateDB: <https://www.innatedb.com/>
#'
#' @seealso <https://github.com/hancockinformatics/pathlinkR/>
#'
#' @examples
#' data("exampleDESeqResults")
#'
#' ppiBuildNetwork(
#'     rnaseqResult=exampleDESeqResults[[1]],
#'     filterInput=TRUE,
#'     order="zero"
#' )
#'
ppiBuildNetwork <- function(
        rnaseqResult,
        filterInput=TRUE,
        columnFC=NA,
        columnP=NA,
        pCutoff=0.05,
        fcCutoff=1.5,
        order="zero",
        hubMeasure="betweenness",
        ppiData=innateDbPPI
) {

    data_env <- new.env(parent=emptyenv())
    data("innateDbPPI", "mappingFile", envir=data_env, package="pathlinkR")
    innateDbPPI <- data_env[["innateDbPPI"]]
    mappingFile <- data_env[["mappingFile"]]

    stopifnot(
        "Rownames of 'rnaseqResult` must contain Ensembl gene IDs"={
            grepl(pattern="ENSG", x=rownames(rnaseqResult)[1])
        }
    )
    stopifnot(order %in% c("zero", "first", "minSimple"))
    stopifnot(hubMeasure %in% c("betweenness", "degree", "hubscore"))
    stopifnot(
        "'ppiData' must have columns 'ensemblGeneA', 'ensemblGeneB'"=all(
            c("ensemblGeneA", "ensemblGeneB") %in% colnames(ppiData)
        )
    )

    if (is(rnaseqResult, "DESeqResults")) {
        rnaseqResult <- rnaseqResult %>%
            as.data.frame() %>%
            rename("LogFoldChange"=log2FoldChange, "PAdjusted"=padj)

    } else if (is(rnaseqResult, "TopTags")) {
        rnaseqResult <- rnaseqResult %>%
            as.data.frame() %>%
            rename("LogFoldChange"=logFC, "PAdjusted"=FDR)

    } else {

        if (filterInput) {
            stopifnot(
                "If 'rnaseqResult' is a simple data frame, and
                'filterInput=TRUE', you must provide 'columnFC' and
                'columnP'"= {
                    !any(is.na(columnFC), is.na(columnP))
                }
            )
            rnaseqResult <- rnaseqResult %>%
                rename(
                    "LogFoldChange"=all_of(columnFC),
                    "PAdjusted"=all_of(columnP)
                )
        }
    }

    df <- tibble::as_tibble(rownames_to_column(rnaseqResult, "gene"))

    if (filterInput) {
        df <- filter(
            df,
            PAdjusted < pCutoff,
            abs(LogFoldChange) > log2(fcCutoff)
        )
    }

    ## Check for and remove any duplicate IDs, warning the user when this occurs
    dfClean <- distinct(df, gene, .keep_all=TRUE)
    geneVector <- unique(dfClean[["gene"]])

    lostIds <- df[["gene"]][duplicated(df[["gene"]])]

    if (length(geneVector) < nrow(df)) {
        numDups <- nrow(df) - length(geneVector)

        message(
            "INFO: Found ", numDups,
            "duplicate IDs in the input column, which have been removed:"
        )

        if (numDups <= 10) {
            message(str_wrap(
                paste(lostIds, collapse=", "),
                indent=2,
                exdent=2
            ))
        } else {
            message(str_wrap(
                paste0(paste(lostIds[seq_len(10)], collapse=", "), "..."),
                indent=2,
                exdent=2
            ))
        }
    }

    ppiDataEnsembl <- select(ppiData, starts_with("ensembl"))

    if (order == "zero") {
        edgeTable <- ppiDataEnsembl %>% filter(
            ensemblGeneA %in% geneVector & ensemblGeneB %in% geneVector
        )
    } else {
        edgeTable <- ppiDataEnsembl %>% filter(
            ensemblGeneA %in% geneVector | ensemblGeneB %in% geneVector
        )
    }

    networkInit <- edgeTable %>%
        as_tbl_graph(directed=FALSE) %>%
        ppiRemoveSubnetworks() %>%
        as_tbl_graph() %>%
        mutate(
            degree=centrality_degree(),
            betweenness=centrality_betweenness(),
            seed=(name %in% geneVector)
        ) %>%
        select(-comp)

    ## Perform node filtering/trimming for minimum order networks, and
    ## recalculate degree and betweenness
    if (order == "minSimple") {

        networkOut1 <- networkInit %>%
            filter(!(degree == 1 & !seed), !(betweenness == 0 & !seed)) %>%
            mutate(
                degree=centrality_degree(),
                betweenness=centrality_betweenness()
            )

    } else {
        networkOut1 <- networkInit
    }

    networkOut2 <-
        if (hubMeasure == "betweenness") {
            networkOut1 %>% mutate(hubScoreBtw=betweenness)
        } else if (hubMeasure == "degree") {
            networkOut1 %>% mutate(hubScoreDeg=degree)
        } else if (hubMeasure == "hubscore") {
            networkOut1 %>% mutate(hubScoreHub=centrality_hub())
        }

    if (nrow(tibble::as_tibble(networkOut2)) > 2000) {
        message(
            "Your network contains more than 2000 nodes, and will likely be ",
            "difficult to interpret when plotted."
        )
    }

    networkFinal <- networkOut2 %>%
        left_join(
            select(mappingFile, "name"=ensemblGeneId, hgncSymbol),
            by="name",
            multiple="all"
        ) %>%
        left_join(dfClean, by=c("name"="gene"), multiple="all")

    attr(networkFinal, "order") <- order
    return(networkFinal)
}
