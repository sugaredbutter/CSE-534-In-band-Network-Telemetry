library(ggplot2)

file_path <- "" #Path for data (csv file)
save_folder <- "" #Path for graphs


#Format : 
#Count,Timestamp,NodeID,Lvl1_Ingress_ID,Lvl1_Egress_ID,HopLatency,QueueID,QueueDepth,IngressTS,EgressTS,Lvl2_IE,EgressTX,BufferInfo,ChecksumComp


data <- read.csv(file_path)

file_name <- basename(file_path)

#Current Switch (Node 1 = Switch 1)
filtered_data <- subset(data, NodeID == 1)

#Interpret time stamp properly
filtered_data$Timestamp <- as.POSIXct(filtered_data$Timestamp, format="%Y-%m-%d %H:%M:%OS")


#Print Statistics
mean_hop_latency <- mean(filtered_data$HopLatency, na.rm = TRUE)
print(paste("1 Mean Hop Latency:", mean_hop_latency, "microseconds"))
mean_queue_depth <- mean(filtered_data$QueueDepth, na.rm = TRUE)
print(paste("1 Mean Queue Depth:", mean_queue_depth, "packets"))



#Make it so time starts at 0 (time stamp is current time currently)
filtered_data$TimeSinceStart <- as.numeric(difftime(filtered_data$Timestamp, min(filtered_data$Timestamp), units = "secs"))

#Hop Latency
ggplot(filtered_data) +
  geom_line(aes(x = TimeSinceStart, y = HopLatency, color = "HopLatency")) + 
  geom_point(aes(x = TimeSinceStart, y = HopLatency, color = "HopLatency")) + 
  scale_color_manual(values = c("HopLatency" = "blue")) +
  labs(
    title = "Hop Latency for NodeID 1 (switch 1)",
    x = "Time (seconds)",
    y = "HopLatency (microseconds)",
    color = "Metric"
  ) +
  #Adjust font sizes for easier viewing in Word Doc
  theme_minimal() +
  theme(
    axis.text = element_text(size = 14),
    axis.title = element_text(size = 16),
    plot.title = element_text(size = 20),
    legend.text = element_text(size = 14),
    legend.title = element_text(size = 16),
  )

png_name <- file.path(save_folder, paste0(file_name, "_switch1_hop.png"))

ggsave(
  filename = png_name,
  plot = last_plot(),
  width = 10,
  height = 6,
  dpi = 300
)

#Queue Depth
ggplot(filtered_data) +
  geom_line(aes(x = TimeSinceStart, y = QueueDepth, color = "QueueDepth")) + 
  geom_point(aes(x = TimeSinceStart, y = QueueDepth, color = "QueueDepth")) + 
  scale_color_manual(values = c("QueueDepth" = "red")) +
  labs(
    title = "Queue Depth for NodeID 1 (switch 1)",
    x = "Time (seconds)",
    y = "QueueDepth (packets)",
    color = "Metric"
  ) +
  #Adjust font sizes for easier viewing in Word Doc
  theme_minimal() +
  theme(
    axis.text = element_text(size = 14),
    axis.title = element_text(size = 16),
    plot.title = element_text(size = 20),
    legend.text = element_text(size = 14),
    legend.title = element_text(size = 16),
  )

png_name <- file.path(save_folder, paste0(file_name, "_switch1_q.png"))

ggsave(
  filename = png_name,
  plot = last_plot(),
  width = 10,
  height = 6,
  dpi = 300
)
