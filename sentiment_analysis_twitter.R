
library(rtweet)
library(dplyr)
library(tidyr)
library(tidytext)
library(ggplot2)
library(textdata)
library(purrr)


## store api keys (these are fake example values; replace with your own keys)
api_key <- "NJrF9CgvH7GAijq5R53qyo2su"
api_secret_key <- "7xfRNSFOkDIiRUToPcbW7n1pSxSSKeNSueXRJombQBrTdx6ePB"

## authenticate via web browser
token <- create_token(
  app = "test_bd_upnvj",
  consumer_key = api_key,
  consumer_secret = api_secret_key)


#Cari tweet tentang topik pilihan Anda, 
#persempit jumlah tweet yang diinginkan dan putuskan untuk memasukkan retweet atau tidak.
kata <- search_tweets("#COVID19", n=1000, include_rts = FALSE)
kata


#Proses setiap set tweet menjadi teks rapi atau objek corpus.
tweet.Kata = kata %>% select(screen_name, text)
tweet.Kata
head(tweet.Kata$text)


#menghapus element http
tweet.Kata$stripped_text1 <- gsub("http\\S+","",tweet.Kata$text)

#gunakan fungsi unnest_tokens() untuk konversi menjadi huruf kecil
#hapus tanda baca, dan id untuk setiap tweet
tweet.Kata_stem <- tweet.Kata %>%
  select(stripped_text1) %>%
  unnest_tokens(word, stripped_text1)
head(tweet.Kata_stem)

#hapus kata-kata stopwords dari daftar kata-kata
cleaned_tweets.Kata <- tweet.Kata_stem %>%
  anti_join(stop_words)
head(cleaned_tweets.Kata)

head(tweet.Kata$text)

#20 kata teratas di tweet #COVID19
cleaned_tweets.Kata %>%
  count(word, sort = TRUE) %>%
  top_n(20) %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(x=word, y = n)) +
  geom_col() +
  coord_flip() +
  theme_classic() +
  labs(x="Count",
       y="Unique word",
       tittle="Unique word counts found in #Canada Tweets")


#Untuk melakukan analisis sentimen menggunakan Bing di tweet COVID19, 
#perintah berikut ini mengembalikan sebuah tibble.
bing_kata = cleaned_tweets.Kata %>% inner_join(get_sentiments("bing")) %>% 
  count(word, sentiment, sort = TRUE) %>% ungroup()


#visualisasi jumlah kata, 
#Anda dapat memfilter dan memplot kata-kata bersebelahan untuk membandingkan 
#emosi positif dan negatif.
bing_kata %>% group_by(sentiment) %>% top_n(10) %>% ungroup() %>% 
  mutate(word = reorder(word, n)) %>% ggplot(aes(word, n, fill = sentiment))+ 
  geom_col(show.legend = FALSE) + facet_wrap(~sentiment, scales = "free_y") + 
  labs(title = "Tweets containing '#COVID19'", y = "Contribution to sentiment", 
       x = NULL) + coord_flip() + theme_bw()

#Fungsi untuk mendapatkan skor sentimen untuk setiap tweet 
sentiment_bing = function(twt){
  twt_tbl = tibble(text = twt) %>%
    mutate(
      stripped_text = gsub("http\\S+","",text)
    )%>%
    unnest_tokens(word, stripped_text) %>%
    anti_join(stop_words) %>%
    inner_join(get_sentiments("bing")) %>%
    count(word,sentiment, sort = TRUE) %>%
    ungroup() %>%
    #buat kolom "skor", yang menetapkan -1 untuk semua kata negatif, 
    #dan 1 untuk kata positif
    mutate(
      score = case_when(
        sentiment == 'negative'~n*(-1),
        sentiment == 'positive'~n*1)
    )
  #menghitung total score
  sent.score = case_when(
    nrow(twt_tbl)==0~0, #jika tidak ada kata, skor adalah 0
    nrow(twt_tbl)>0~sum(twt_tbl$score) #selainnya, jumlah positif dan negatif
  )
  #untuk melacak tweet mana yang tidak mengandung kata sama sekali dari daftar bing
  zero.type = case_when(
    nrow(twt_tbl)==0~"Type 1", #Type 1: tidak ada kata sama sekali, zero = no
    nrow(twt_tbl)>0~"Type 2" #Type 2: nol berarti jumlah kata = 0
  )
  list(score = sent.score, type = zero.type, twt_tbl = twt_tbl)
}


#menerapkan fungsi
#Fungsi lapply mengembalikan list semua skor sentimen, jenis, dan tabel tweet
kata_sent = lapply(kata$text, function(x){sentiment_bing(x)})   
kata_sent


#membuat tibble yang menentukan kata, skor, dan jenisnya
kata_sentiment = bind_rows(tibble(kata = '#COVID19', 
                                  score = unlist(map(kata_sent, 'score')), 
                                  type = unlist(map(kata_sent, 'type'))))

#kita dapat melihat beberapa karakteristik sentimen di setiap kelompok. 
#Berikut adalah histogram sentimen tweet.
ggplot(kata_sentiment, aes(x=score, fill = kata)) + 
  geom_histogram(bins = 15, alpha= .6) + facet_grid(~kata) + theme_bw()
















