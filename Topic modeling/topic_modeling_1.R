# install packages
#install.packages("tm")
#install.packages("topicmodels")
#install.packages("reshape2")
#install.packages("ggplot2")
#install.packages("wordcloud")

#install.packages("pals")
#install.packages("SnowballC")
#install.packages("lda")
#install.packages("ldatuning")
# install klippy for copy-to-clipboard button in code chunks
#remotes::install_github("rlesur/klippy")

# set options
options(stringsAsFactors = F)         # no automatic data transformation
options("scipen" = 100, "digits" = 4) # supress math annotation
# load packages
library(knitr) 
library(kableExtra) 
library(DT)
library(tm)
library(topicmodels)
library(reshape2)
library(ggplot2)
library(wordcloud)
library(pals)
library(SnowballC)
library(lda)
library(ldatuning)
library(tidyverse)
library(flextable)
library(qdapRegex) 
# activate klippy for copy-to-clipboard button
klippy::klippy()
library("spacyr")
spacy_initialize(model = "it_core_news_sm")
setwd("D:/University of Trieste/project/Corpus_analysis")
#install.packages("stopwords")
#head(stopwords::stopwords("Italian"), 20) 



setwd("D:/University of Trieste/project/Corpus_analysis")
#install.packages("stopwords")
#head(stopwords::stopwords("Italian"), 20) 

file_name <- "data/carteggio.svevo3.csv"
corpus <- read.csv(file_name, sep=';', encoding = "UTF-8")
corpus %>%
  str
#view(corpus)

corpus$mainLanguage<-as.factor(corpus$mainLanguage)
corpus$sender<-as.factor(corpus$sender)
corpus$year<-as.factor(corpus$year)

# let's check the number of language used 
levels(corpus$mainLanguage)
# Let's check the number of senders
levels(corpus$sender)
#number of year
levels(corpus$year)

# Let's count the number of letter's send in each lenguage

sum(corpus$mainLanguage == 'ENG')

sum(corpus$mainLanguage == "FRE")

sum(corpus$mainLanguage == "GER")
sum(corpus$mainLanguage == "ITA")

# There more text writing in Itlian implied have more inside than order text. So we will study text writing
# in italian and then check those writing in french.  

# Let's filter the dataset
corpus_it<- dplyr::filter(corpus, mainLanguage %in%c("ITA"))

#view(corpus_it)

# Let's select the the main feature that will be used
names(corpus_it)

fin_corpus<- select(corpus_it, year, text, sender)
#fin_corpus<-filter(fin_corpus, !(year %in% c("1921","1924")))
fin_corpus <-droplevels(fin_corpus)

# new way 
# to useful files for italians stopwords and proper nouns in italian language
load("itastopwords.rda")
load("vocabolarioNomiPropri.rda")
corp<- fin_corpus %>%select(year,text)%>%
  group_by(year) %>%
  paste0()


ll<-Corpus(VectorSource(fin_corpus$text))
print(ll)
inspect(ll[1:2])

#clining 

corpus_t<-tm_map(ll,tolower)

# remouve number
corpus_t<-tm_map(corpus_t,removeNumbers)
#remove punctuation
corpus_t<-tm_map(corpus_t,removePunctuation,preserve_intra_word_dashes = TRUE)
#remouve all pucntion which is not remouved by remouve puctuation
corpus_t <- tm_map(corpus_t, removeWords,c("d'","l'","un'", "—'" ))
# delete white spaces which originate from the removed strings
corpus_t <- tm_map(corpus_t , stripWhitespace)
# remove words which are useless in the bigrams
corpus_t <- tm_map(corpus_t,removeWords,c("devono","moglie","—","-","trieste", "essere", "u","qui", "fffd", "ancora", "volta", "tre", "due", "anni", "dopo", "aver","ultimi", "vuol","dire", "dovrebbe","qualche","giorno", "p", "vista", "punto", "n","mesi", "pochi", "migliaia", "milioni","piazza", "troppo", "tempo","streaming","stato","fatto","fare", "fra","poco","detto"))
# remove stopwords from "itastopwords.rda" file
corpus_t <- tm_map(corpus_t, removeWords, itastopwords)
# remove default R stopwords for italian language
corpus_t <- tm_map(corpus_t, removeWords, stopwords("italian"))
# remove proper nouns
corpus_t <- tm_map(corpus_t, removeWords, row.names(vocabolarioNomiPropri))

dtm1=DocumentTermMatrix(corpus_t)
inspect(dtm1)


#Topic Modelling step


# create models with different number of topics
result <- ldatuning::FindTopicsNumber(
  dtm1,
  topics = seq(from = 2, to = 20, by = 1),
  metrics = c("CaoJuan2009",  "Deveaud2014"),
  method = "Gibbs",
  control = list(seed = 77),
  verbose = TRUE
)

FindTopicsNumber_plot(result)

# number of topics
K <- 5
# set random number generator seed
set.seed(9161)
# compute the LDA model, inference via 1000 iterations of Gibbs sampling
topicModel <- LDA(dtm1, K, method="Gibbs", control=list(iter = 2000, verbose = 25))


# have a look a some of the results (posterior distributions)
tmResult <- posterior(topicModel)
# format of the resulting object
attributes(tmResult)
tmResult$topics
terms(topicModel, 20)