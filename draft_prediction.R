library(swiftcap)
data (blogs)
fit <- ngram (blogs, N=3)
predict (fit, "What is the next")



N           = 1:3
freq_cutoff = 1
rank_cutoff = 5
delimiters  = ' \r\n\t.,;:\\"()?!'


# transform the text input into clean sentences
sentences <- clean_sentences (split_by_sentence (blogs))

# split the sentences into ngrams
ngrams <- split_by_ngram (sentences, min (N), max (N), delimiters)

# determine the frequency/count of each phrase
ngrams <- ngrams [, list (frequency = .N), by = phrase]



# extract the context and the next word for each ngram
ngrams [, word    := last_word (phrase),        by = phrase]
ngrams [, context := except_last_word (phrase), by = phrase]

# calculate the MLE of the probability of occurrence for each n-gram
context <- ngrams [, sum (frequency), by = context]
head(context)
setnames (context, c("context", "context_frequency"))

# through merging of context and ngrams, calculate the probability
setkeyv (context, "context")
setkeyv (ngrams, "context")

# calculate the maximum liklihood estimate
ngrams [context, p := frequency / context_frequency]
head(ngrams, 30)


ngrams <- ngram_mle (ngrams)


# exclude ngrams that are below the frequency cut-off
ngrams <- ngrams [ frequency >= freq_cutoff, list (phrase, context, word, p) ]

# do not predict a 'start of sentence'
ngrams <- ngrams [word != "^"]

# do not predict 'end of sentence' with no context or at the start of a sentence
ngrams <- ngrams [!(context == ""  & word == "$")]
ngrams <- ngrams [!(context == "^" & word == "$")]


# mark each n-gram as a 1, 2, ... N gram
regex <- paste0 ("[", delimiters, "]+")
ngrams [, n := unlist (lapply (stri_split (phrase, regex = regex), length)) ]

# keep only most likely words for each context
ngrams <- ngrams [ order (context, -p)]
ngrams [, rank := 1:.N, by = context]
ngrams <- ngrams [ rank <= rank_cutoff ]


model <- list (ngrams      = ngrams,
               N           = N,
               freq_cutoff = freq_cutoff,
               rank_cutoff = rank_cutoff)
class (model) <- "ngram"

phrase <- "What is the next"
words <- split_by_word (clean_sentences (split_by_sentence (phrase)))


if (!stri_detect (phrase, regex = ".*[\\.!?][[:blank:]]*$"))
    words <- head (words, -1)

predictions <- NULL
object <- fit

for (n in sort (object$N, decreasing = TRUE)) {
    n = 1
    # ensure there are enough previous words
    # for example, a trigram ngrams needs 2 previous words
    if (length (words) >= n-1) {

        print(words) #ML
        # grab the necessary context; last 'n-1' words
        ctx <- paste (tail (words, n-1), collapse = " ")

        # find matching context in the model
        predictions <- object$ngrams [ context == ctx, list (word, p, n, rank)]
        if (nrow (predictions) > 0) {

            # basic translations
            # TODO ugly; should handle in a better way
            predictions [word == "$", word := "."]
            predictions [word == "###", word := NA]

            # exclude any missing predictions
            predictions <- predictions [complete.cases (predictions)]

            # only keep the top 'rank' predictions
            predictions <- predictions [rank <= rank]

            break
        }
    }
}

return (predictions)
