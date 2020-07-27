library('xlsx')
library('ggplot2')
library('cowplot')

# AANPASSEN VOOR RUNNEN
matrix<-"DBS"

# Prefix to the network drive; Generally Y:/ or T:/metab
prefix <- "Y:/"


# Read in project list
setwd(paste(prefix, "Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects", sep="/"))
Overview<-read.xlsx(file="DIMS_Project_Overview.xlsx",sheetIndex=1,stringsAsFactors=F)
Overview<-subset(Overview, Overview$Matrix %in% matrix & Overview$Pos.Contr.Analyse %in% 'Ja')

Pos_Contr_merge<-as.data.frame(matrix(ncol=7,nrow=0))
colnames(Pos_Contr_merge)<-c("HMDB.code","HMDB.name","Sample","Zscore","Matrix","Rundate","Project")

# Read in data
for (i in 1:length(Overview$Project)) {
  project<-Overview[i,'Project.Naam']
  load(paste0(prefix, "/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Kwaliteit_Validatie/Pos_Contr_results/",
             matrix,'/Pos_Contr_',project,".RData"))
  Pos_Contr_merge<-rbind(Pos_Contr_merge,Pos_Contr)
  Pos_Contr<-NULL
  project<-NULL
}

### SELECT WHAT TO PLOT
PA<-'P1002.1_Zscore'    #PA
PKU<-'P1003.1_Zscore'   #PKU
LPI<-'P1005.1_Zscore'   #LPI

p1<-ggplot(subset(Pos_Contr_merge, Sample %in% PA), aes(Project,Zscore))+
  geom_point(aes(col=Project),size=3)+
  geom_text(aes(label=sprintf("%0.2f", round(Zscore, digits = 2))), nudge_x = 0.2, nudge_y = 0.2, size=3)+
  labs(x='',y='Zscore')+
  facet_wrap(~HMDB.name,ncol=1,scales='free_y')+
  theme(axis.text.x=element_blank(), legend.position='none')
p2<-ggplot(subset(Pos_Contr_merge, Sample %in% LPI), aes(Project,Zscore))+
  geom_point(aes(col=Project),size=3)+
  geom_text(aes(label=sprintf("%0.2f", round(Zscore, digits = 2))), nudge_x = 0.2, nudge_y = 0.2, size=3)+
  labs(x='',y='Zscore')+
  facet_wrap(~HMDB.name,ncol=1,scales='free_y')+
  theme(axis.text.x=element_blank(), legend.position='none')
p3<-ggplot(subset(Pos_Contr_merge, Sample %in% PKU), aes(Project,Zscore))+
  geom_point(aes(col=Project),size=3)+
  geom_text(aes(label=sprintf("%0.2f", round(Zscore, digits = 2))), nudge_x = 0.2, nudge_y = 0.2, size=3)+
  labs(x='',y='Zscore')+
  facet_wrap(~HMDB.name,ncol=1,scales='free_y')+
  theme(axis.text.x=element_text(angle = 90, hjust = 0, size=10), legend.position='none')

plot_grid(p1,p2,p3,ncol=1,axis='rlbt',rel_heights=c(1,1,1.25))
