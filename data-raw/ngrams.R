
options (cache_dir = ".ecache")
options (verbose = FALSE)

# where is the data stored?
data_path <- "data-raw"

# unzip the data files, only if necessary
txts <- list.files (path = data_path, pattern = "\\.txt$", recursive = TRUE)
if (length (txts) == 0) {

    zips <- list.files (path = data_path, pattern = "\\.zip$", full.names = TRUE, recursive = TRUE)
    for (zip in zips) unzip (zip, exdir = dirname (zip))
}

# create a corpus from the text input
files <- list.files (data_path, pattern = "\\.txt$", full.names = TRUE)
text <- unlist (lapply (files, readLines, skipNul = TRUE))

# remove the txt file
for (txt in txts){
    print(txt)
    if (file.exists (paste0(data_path, "/", txt))
        file.remove (txt)
}
file.remove('data-raw\\en_US.twitter.txt')

# sample the original input
p <- 0.02
if (p < 1.0) {
    index <- as.logical (rbinom (n = length (text), size = 1, prob = p))
    text <- text [index]
}

# ngrams <- ecache ({
#
#     # create the ngram model
#     ngrams <- ngram (text, N = 1:3, sample = 0.01)
#
#
# })

model <- ngram (text)

# persist the ngram model for internal use within the package
devtools::use_data (model)
