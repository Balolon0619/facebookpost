import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facebook Post',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PostPage(),
    );
  }
}

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final TextEditingController _subtextController = TextEditingController();
  File? _image;
  List posts = [];

  final _logger = Logger('PostPage');

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _createPost() async {
    if (_image == null || _subtextController.text.isEmpty) {
      _logger.warning('Image or Subtext is missing');
      return;
    }

    final uri = Uri.parse('http://localhost:3000/api/posts');
    final request = http.MultipartRequest('POST', uri);

    final imageFile = await http.MultipartFile.fromPath('image', _image!.path);

    request.files.add(imageFile);
    request.fields['subtext'] = _subtextController.text;

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        _getPosts();
        setState(() {
          _image = null;
          _subtextController.clear();
        });
        _logger.info('Post created successfully');
      } else {
        _logger.severe(
          'Failed to create post. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.severe('Error during post creation: $e');
    }
  }

  Future<void> _getPosts() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/posts'),
      );

      if (response.statusCode == 200) {
        setState(() {
          posts = json.decode(response.body);
        });
      } else {
        _logger.severe(
          'Failed to load posts. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.severe('Error fetching posts: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getPosts();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final isoString = dateStr.replaceFirst(' ', 'T');
      final parsed = DateTime.parse(isoString).toLocal();
      return DateFormat.yMMMd().add_jm().format(parsed);
    } catch (e) {
      print("Date parse error: $e");
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Facebook Post')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Post creation section
              TextField(
                controller: _subtextController,
                decoration: InputDecoration(labelText: 'Subtext'),
              ),
              SizedBox(height: 16),
              Center(
                child: _image == null
                    ? IconButton(
                        icon: Icon(Icons.image, size: 48, color: Colors.blueGrey),
                        onPressed: _pickImage,
                      )
                    : Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Image.file(
                            _image!,
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _image = null;
                              });
                            },
                          ),
                        ],
                      ),
              ),
              SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _createPost,
                  child: Text('Create Post'),
                ),
              ),
              SizedBox(height: 24),
              // Posts list
              posts.isEmpty
                  ? Center(child: Text('No posts yet.'))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        final int reacts = 666;
                        final int comments = 555;
                        final int shares = 365;

                        const String commentProfile =
                            'https://plus.unsplash.com/premium_photo-1744754825046-71455f020060?q=80&w=1974&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 12),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        'https://plus.unsplash.com/premium_photo-1744754825046-71455f020060?q=80&w=1974&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                                      ),
                                      radius: 20,
                                      onBackgroundImageError: (exception, stackTrace) {
                                        print('Error loading image: $exception');
                                      },
                                    ),
                                    SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Jackie B.',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        Text(
                                          _formatDate(post['created_at']),
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                _buildStyledPostText(post['subtext'] ?? ''),
                                SizedBox(height: 10),
                                if (post['image'] != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return Image.network(
                                          'http://localhost:3000/uploads/${post['image']}',
                                          width: constraints.maxWidth,
                                          height: 500,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, exception, stackTrace) {
                                            print ('Error loading image: $exception');
                                            return const Text('Failed to load image');
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.thumb_up, color: Colors.blue, size: 20),
                                          const Icon(Icons.favorite, color: Colors.red, size: 20),
                                          Icon(Icons.emoji_emotions, color: Colors.yellow[700], size: 20),
                                          const SizedBox(width: 10),
                                          Text("$reacts Reacts"),
                                        ],
                                      ),
                                      Text("$comments Comments • $shares Shares"),
                                    ],
                                  ),
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _actionButton(Icons.thumb_up_alt_outlined, "Like"),
                                    _actionButton(Icons.comment_outlined, "Comment"),
                                    _actionButton(Icons.share_outlined, "Share"),
                                  ],
                                ),
                                const Divider(),
                                _commentSection(commentProfile),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledPostText(String text) {
    List<TextSpan> spans = [];
    RegExp exp = RegExp(r"#\w+");
    text.splitMapJoin(
      exp,
      onMatch: (match) {
        spans.add(
          TextSpan(
            text: match.group(0),
            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        );
        return "";
      },
      onNonMatch: (nonMatch) {
        spans.add(TextSpan(text: nonMatch, style: const TextStyle(color: Colors.black)));
        return "";
      },
    );

    return RichText(
      text: TextSpan(
        children: spans,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: Colors.grey[800]),
      label: Text(label, style: TextStyle(color: Colors.grey[800])),
    );
  }

  Widget _commentSection(String commentProfile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(commentProfile),
            radius: 15,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Write a comment...",
                border: InputBorder.none,
              ),
            ),
          ),
          _iconButton(Icons.message),
          _iconButton(Icons.emoji_emotions),
          _iconButton(Icons.camera_alt),
          _iconButton(Icons.gif_box),
          _iconButton(Icons.sticky_note_2),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon) {
    return IconButton(
      onPressed: () {},
      icon: Icon(icon, color: Colors.grey[800]),
    );
  }
}
