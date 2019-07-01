# Build stage
FROM swift:5.0 AS build

# Build Mint
COPY . /Mint
WORKDIR /Mint
RUN swift build --disable-sandbox -c release

# Release stage
FROM swift:5.0 AS release

# Copy Mint executable from build stage
COPY --from=build /Mint/.build/release/mint /usr/local/bin
