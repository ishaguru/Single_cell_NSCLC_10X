---
title: "Seurat"
output: html_document
---
  
# load libraries
library(Seurat)
library(SeuratDisk)
library(tidyverse)

# Loading the NSCLC dataset
nsclc.data <- Read10X_h5(filename = '20k_NSCLC_DTC_3p_nextgem_Multiplex_count_raw_feature_bc_matrix.h5')
str(nsclc.sparse.m)
cnt <-  nsclc.data$`Gene Expression`


# Initializing the Seurat object with the raw (non-normalized data).
nsclc.seurat.obj <- CreateSeuratObject(counts = cnt, project = "NSCLC", min.cells = 3, min.features = 200)
nsclc.seurat.obj
# 29552 features across 42081 samples

## -------------------------------------------------------------------------------------------------------

# 1. Quality Control 
View(nsclc.seurat.obj@meta.data)
# % Mitochondrial gene reads
nsclc.seurat.obj[["percent.mit"]] <- PercentageFeatureSet(nsclc.seurat.obj, pattern = "^MT-")

#violin plot
VlnPlot(nsclc.seurat.obj, features = c("nFeature_RNA", "nCount_RNA", "percent.mit"), ncol = 3)
FeatureScatter(nsclc.seurat.obj, feature1 = "nCount_RNA", feature2 = "nFeature_RNA") +
  geom_smooth(method = 'lm')

## -------------------------------------------------------------------------------------------------------

# 2. Filtering 
nsclc.seurat.obj <- subset(nsclc.seurat.obj, subset = nFeature_RNA > 200 & nFeature_RNA < 2500 & 
                             percent.mit < 5)

# 3. Normalize data 
nsclc.seurat.obj <- NormalizeData(nsclc.seurat.obj, normalization.method = "LogNormalize", scale.factor = 10000)
str(nsclc.seurat.obj)

## -------------------------------------------------------------------------------------------------------

# 4. Identify highly variable features 
nsclc.seurat.obj <- FindVariableFeatures(nsclc.seurat.obj, selection.method = "vst", nfeatures = 2000)

# Identify the 10 most highly variable genes
top10 <- head(VariableFeatures(nsclc.seurat.obj), 10)

# plot variable features 
var_feature_plot <- VariableFeaturePlot(nsclc.seurat.obj)
LabelPoints(plot = var_feature_plot, points = top10, repel = TRUE)

## -------------------------------------------------------------------------------------------------------

# 5. Scaling 
gene_list <- rownames(nsclc.seurat.obj)
nsclc.seurat.obj <- ScaleData(nsclc.seurat.obj, features = gene_list)
str(nsclc.seurat.obj)

# 6. Perform Linear dimensionality reduction --------------
nsclc.seurat.obj <- RunPCA(nsclc.seurat.obj, features = VariableFeatures(object = nsclc.seurat.obj))

# visualize PCA results
print(nsclc.seurat.obj[["pca"]], dims = 1:5, nfeatures = 5)
DimHeatmap(nsclc.seurat.obj, dims = 1, cells = 500, balanced = TRUE)


# determine dimensionality of the data
ElbowPlot(nsclc.seurat.obj)

## -------------------------------------------------------------------------------------------------------

# 7. Clustering 
nsclc.seurat.obj <- FindNeighbors(nsclc.seurat.obj, dims = 1:15)

#setting resolution
nsclc.seurat.obj <- FindClusters(nsclc.seurat.obj, resolution = c(0.1,0.3, 0.5, 0.7, 1))
View(nsclc.seurat.obj@meta.data)

DimPlot(nsclc.seurat.obj, group.by = "RNA_snn_res.0.5", label = TRUE)

# setting identity of clusters
Idents(nsclc.seurat.obj)
Idents(nsclc.seurat.obj) <- "RNA_snn_res.0.1"

# non-linear dimensionality reduction 
nsclc.seurat.obj <- RunUMAP(nsclc.seurat.obj, dims = 1:15)
# individual clusters
DimPlot(nsclc.seurat.obj, reduction = "umap")

## -------------------------------------------------------------------------------------------------------
